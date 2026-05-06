import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../core/crypto/field_cipher.dart';
import '../../core/crypto/password_kdf.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/db_snapshot_repository.dart';

/// 加密备份包的结构版本。
///
/// - v1（旧）：密文未绑定 KDF 元数据，攻击者可改 `kdf.params` 降低迭代数后
///   对密文做离线爆破。由于存在安全漏洞，v1 已不再支持导入。
/// - v2（当前）：导出时把 `kdf` 子对象的规范化 JSON 作为 AAD 传入 AES-GCM，
///   任何对元数据的篡改都会导致 MAC 校验失败。
const int backupFormatVersion = 2;

/// 备份口令最小长度。
const int backupMinPasswordLength = 10;

/// 备份包可被接受的最大字节数（防止 `jsonDecode` 触发 OOM）。
const int backupMaxBytes = 50 * 1024 * 1024;

ValidationError? validateBackupPassword(String password) {
  if (password.isEmpty) {
    return const ValidationError('password must not be empty');
  }
  if (password.length < backupMinPasswordLength) {
    return const ValidationError('password too short for backup encryption');
  }
  return null;
}

/// 导出备份：
/// 1. [DbSnapshotRepository] 把所有表导出为 JSON
/// 2. Argon2id(password, salt) 派生 32 字节 SecretKey
/// 3. AES-GCM-256 加密 JSON，得到 nonce/ciphertext/mac
/// 4. 将元信息 + 密文打包为 JSON 字符串（Base64 编码字段）
class ExportBackupUseCase {
  ExportBackupUseCase(
    this._snapshot, {
    PasswordKdf? kdf,
    FieldCipher? cipher,
    List<int> Function(int)? randomBytes,
  }) : _kdf = kdf ?? PasswordKdf(),
       _cipher = cipher ?? FieldCipher(),
       _random = randomBytes ?? _defaultRandomBytes;

  final DbSnapshotRepository _snapshot;
  final PasswordKdf _kdf;
  final FieldCipher _cipher;
  final List<int> Function(int) _random;

  Future<Result<String, AppError>> call({required String password}) async {
    final passwordError = validateBackupPassword(password);
    if (passwordError != null) {
      return Err(passwordError);
    }
    try {
      final snap = await _snapshot.export();
      final plaintext = jsonEncode(snap);
      final salt = _random(16);
      final derived = await _kdf.derive(password: password, salt: salt);
      if (derived.isErr) return Err(derived.errorOrNull!);

      // 规范化 kdf 元数据：作为 AAD 绑定到密文。
      // 注意：key 顺序必须与导入端完全一致，所以固定列出而不用 Map 字面量。
      final kdfMeta = {
        'algo': 'argon2id',
        'salt': base64Encode(salt),
        'params': {
          'm': _kdf.memoryKib,
          't': _kdf.iterations,
          'p': _kdf.parallelism,
          'l': _kdf.hashLength,
        },
      };
      final aad = utf8.encode(jsonEncode(kdfMeta));
      final ct = await _cipher.encryptString(
        plaintext,
        derived.valueOrNull!,
        aad: aad,
      );
      if (ct.isErr) return Err(ct.errorOrNull!);

      final pack = {
        'version': backupFormatVersion,
        'kdf': kdfMeta,
        'cipher': {
          'algo': 'aes-gcm-256',
          // FieldCipher 已打包 nonce||cipher||mac 为单一 base64；
          // 这里直接沿用字段级加密的封装，解密侧一致。
          'blob': ct.valueOrNull,
        },
      };
      return Ok(jsonEncode(pack));
    } catch (e) {
      return Err(StorageError('export failed: $e'));
    }
  }
}

/// 导入备份：
/// 1. 解析 JSON，校验 version & kdf.algo & cipher.algo
/// 2. Argon2id(password, salt) 派生同一 SecretKey
/// 3. AES-GCM-256 解密，得到快照 JSON
/// 4. [DbSnapshotRepository.restore] 覆盖本地数据库
class ImportBackupUseCase {
  ImportBackupUseCase(this._snapshot, {FieldCipher? cipher})
    : _cipher = cipher ?? FieldCipher();

  final DbSnapshotRepository _snapshot;
  final FieldCipher _cipher;

  Future<Result<void, AppError>> call({
    required String package,
    required String password,
  }) async {
    final passwordError = validateBackupPassword(password);
    if (passwordError != null) {
      return Err(passwordError);
    }
    if (package.isEmpty) {
      return const Err(ValidationError('empty backup package'));
    }
    // 备份包为 JSON 字符串，其内容均为 ASCII/Base64，UTF-8 字节数与
    // String.length（UTF-16 代码单元数）近似相等，无需实体化字节数组做比较。
    // 直接用 length 可避免 2× 峰值内存占用（尤其是接近 backupMaxBytes 上限时）。
    if (package.length > backupMaxBytes) {
      return const Err(ValidationError('backup package too large'));
    }
    try {
      final pack = jsonDecode(package) as Map<String, dynamic>;
      final version = pack['version'];
      if (version != backupFormatVersion) {
        return Err(ValidationError('unsupported backup version: $version'));
      }
      final kdfMeta = pack['kdf'] as Map<String, dynamic>?;
      if (kdfMeta == null || kdfMeta['algo'] != 'argon2id') {
        return const Err(ValidationError('unsupported kdf'));
      }
      final cipherMeta = pack['cipher'] as Map<String, dynamic>?;
      if (cipherMeta == null || cipherMeta['algo'] != 'aes-gcm-256') {
        return const Err(ValidationError('unsupported cipher'));
      }
      final saltRaw = kdfMeta['salt'];
      if (saltRaw is! String) {
        return const Err(ValidationError('backup kdf missing or invalid salt'));
      }
      final salt = base64Decode(saltRaw);
      final paramsRaw = kdfMeta['params'];
      if (paramsRaw is! Map) {
        return const Err(ValidationError('backup kdf missing or invalid params'));
      }
      final params = paramsRaw.cast<String, dynamic>();
      // 校验 KDF 参数范围，防止恶意备份包通过极大 memoryKib 触发 OOM 崩溃。
      // AAD 绑定虽可防止 MAC 校验通过，但 PasswordKdf 构造发生在解密之前，
      // 因此必须在实例化前做服务端范围限制。
      const maxMemoryKib = 512 * 1024; // 512 MiB
      const maxIterations = 20;
      const maxParallelism = 8;
      const maxHashLength = 64;
      final m = params['m'];
      final t = params['t'];
      final p = params['p'];
      final l = params['l'];
      if (m is! int || m <= 0 || m > maxMemoryKib ||
          t is! int || t <= 0 || t > maxIterations ||
          p is! int || p <= 0 || p > maxParallelism ||
          l is! int || l < 16 || l > maxHashLength) {
        return const Err(ValidationError('invalid kdf params in backup'));
      }
      final kdf = PasswordKdf(
        memoryKib: m,
        iterations: t,
        parallelism: p,
        hashLength: l,
      );
      final derived = await kdf.derive(password: password, salt: salt);
      if (derived.isErr) return Err(derived.errorOrNull!);
      final blobRaw = cipherMeta['blob'];
      if (blobRaw is! String) {
        return const Err(ValidationError('backup cipher blob missing or invalid'));
      }
      final blob = blobRaw;
      // v2 始终使用 kdf 元数据作为 AAD；任何对元数据的篡改都会导致 MAC 校验失败。
      final aad = utf8.encode(jsonEncode(kdfMeta));
      final plain = await _cipher.decryptString(
        blob,
        derived.valueOrNull!,
        aad: aad,
      );
      if (plain.isErr) {
        return const Err(CryptoError('wrong password or corrupted backup'));
      }
      final decoded = jsonDecode(plain.valueOrNull!);
      if (decoded is! Map) {
        return const Err(ValidationError('backup structure invalid: root is not a map'));
      }
      final snap = decoded.cast<String, dynamic>().map((k, v) {
        if (v is! List) {
          throw ValidationError('backup structure invalid: table "$k" is not a list');
        }
        // 逐元素校验，确保类型不符时立即抛 ValidationError（而非惰性 CastError）
        final typed = <Map<String, dynamic>>[];
        for (var i = 0; i < v.length; i++) {
          final item = v[i];
          if (item is! Map<String, dynamic>) {
            throw ValidationError(
                'backup structure invalid: table "$k"[$i] is not a map (got ${item.runtimeType})');
          }
          typed.add(item);
        }
        return MapEntry(k, typed);
      });
      await _snapshot.restore(snap);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('import failed: $e'));
    }
  }
}

List<int> _defaultRandomBytes(int n) {
  final r = Random.secure();
  return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
}
