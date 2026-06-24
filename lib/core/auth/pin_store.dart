import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/password_kdf.dart';

/// 键值存储抽象，便于测试时注入内存实现。
abstract interface class PinKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// 生产环境：FlutterSecureStorage 适配器。
class SecureStoragePinKv implements PinKeyValueStore {
  SecureStoragePinKv([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// 内存实现（仅测试用）。
class InMemoryPinKv implements PinKeyValueStore {
  final Map<String, String> _m = {};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
}

/// 本地 PIN 码存储 + 校验。
///
/// 设计要点：
/// - 口令熵低（4~6 位数字），必须走慢 KDF（Argon2id）提升暴力破解成本
/// - 派生结果（hash）与 salt 以 Base64 存入 FlutterSecureStorage；明文 PIN 绝不入库
/// - 校验使用常量时间比对（防侧信道）
/// - 生物识别开关与 PIN 独立；生物识别仅作为「快捷通道」，最终凭证仍是 PIN
/// - 失败计数存 secure_storage，超过阈值后附加 [lockedUntilMs] 冷却期
class PinStore {
  PinStore({
    PinKeyValueStore? storage,
    PasswordKdf? kdf,
    Random? random,
  })  : _storage = storage ?? SecureStoragePinKv(),
        _kdf = kdf ?? PasswordKdf(memoryKib: 16384, iterations: 2, hashLength: 32),
        _random = random ?? Random.secure();

  static const _kSalt = 'coffer.pin.salt.v1';
  static const _kHash = 'coffer.pin.hash.v1';
  // v2: salt+hash 合并为单条 JSON，原子写入避免进程崩溃时两字段不一致
  static const _kCredential = 'coffer.pin.credential.v2';
  static const _kBiometricEnabled = 'coffer.pin.biometric_enabled.v1';
  static const _kFailCount = 'coffer.pin.fail_count.v1';
  static const _kLockedUntil = 'coffer.pin.locked_until.v1';

  /// 允许的连续失败次数，超过后进入冷却
  static const int maxFailBeforeLock = 5;

  /// 冷却时长（毫秒）— 5 分钟，OWASP 建议递增锁定
  static const int lockoutMs = 5 * 60 * 1000;

  final PinKeyValueStore _storage;
  final PasswordKdf _kdf;
  final Random _random;

  // Serializes concurrent verifyPin calls to prevent TOCTOU on fail count.
  Future<void>? _verifyLock;

  /// 是否已设置 PIN（首启检测）
  Future<bool> hasPin() async {
    // 优先查 v2 合并键，兼容读旧版 v1 双键
    final cred = await _storage.read(_kCredential);
    if (cred != null) return true;
    final salt = await _storage.read(_kSalt);
    final hash = await _storage.read(_kHash);
    return salt != null && hash != null;
  }

  /// 设置 / 重置 PIN（覆盖旧值，并清零失败计数）
  Future<void> setPin(String pin) async {
    _validateFormat(pin);
    final salt = _generateSalt(16);
    final secret = await _kdf.derive(password: pin, salt: salt);
    final hash = secret.when(
      ok: (k) => k,
      err: (e) => throw StateError('pin derive failed: $e'),
    );
    final bytes = await hash.extractBytes();
    // 原子写入：salt+hash 合并为单条 JSON，避免两次独立写入之间进程崩溃
    // 导致只有 salt 写入、hash 缺失，进而 hasPin() 返回 false 清除用户 PIN。
    final credential = jsonEncode({
      'salt': base64Encode(salt),
      'hash': base64Encode(bytes),
    });
    await _storage.write(_kCredential, credential);
    // 清除旧版 v1 双键（升级迁移）
    await _storage.delete(_kSalt);
    await _storage.delete(_kHash);
    await _storage.delete(_kFailCount);
    await _storage.delete(_kLockedUntil);
  }

  /// 校验 PIN。成功返回 true 并清零失败计数；失败返回 false 并递增。
  /// 若当前处于冷却期，直接返回 false 并不消耗尝试次数。
  Future<PinVerifyResult> verifyPin(String pin) async {
    final prev = _verifyLock;
    final completer = Completer<void>();
    _verifyLock = completer.future;
    try {
      await prev;
      return await _verifyPinImpl(pin);
    } finally {
      completer.complete();
    }
  }

  Future<PinVerifyResult> _verifyPinImpl(String pin) async {
    try {
      return await _verifyPinCore(pin);
    } catch (e) {
      // credential 损坏（JSON 解析失败、类型转换错误等）时，
      // 返回验证失败而非向上传播异常导致应用崩溃。
      if (kDebugMode) debugPrint('verifyPinImpl unexpected error: $e');
      return const PinVerifyResult(
        ok: false,
        lockedUntilMs: 0,
        remainingAttempts: -1,
      );
    }
  }

  Future<PinVerifyResult> _verifyPinCore(String pin) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lockUntil = int.tryParse(await _storage.read(_kLockedUntil) ?? '') ?? 0;
    if (lockUntil > now) {
      return PinVerifyResult(
        ok: false,
        lockedUntilMs: lockUntil,
        remainingAttempts: 0,
      );
    }

    // 读取 v2 合并凭证，兼容旧版 v1 双键
    String? saltB64;
    String? hashB64;
    final credJson = await _storage.read(_kCredential);
    if (credJson != null) {
      final decoded = jsonDecode(credJson);
      if (decoded is! Map) {
        // 凭证损坏（结构异常）：返回专用结果，调用方可据此提示用户重置 PIN
        return const PinVerifyResult(
          ok: false,
          lockedUntilMs: 0,
          remainingAttempts: -1,
        );
      }
      final cred = decoded.cast<String, dynamic>();
      saltB64 = cred['salt'] as String?;
      hashB64 = cred['hash'] as String?;
    } else {
      saltB64 = await _storage.read(_kSalt);
      hashB64 = await _storage.read(_kHash);
    }
    if (saltB64 == null || hashB64 == null) {
      return const PinVerifyResult(ok: false, lockedUntilMs: 0, remainingAttempts: 0);
    }

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);

    final derived = await _kdf.derive(password: pin, salt: salt);
    // 派生失败时，生成与 expected 等长的全零字节再做虚假比对，
    // 保持与成功路径相近的执行时间，消除计时旁道。
    final actual = await derived.when(
      ok: (k) async => await k.extractBytes(),
      err: (e) async => List<int>.filled(expected.length, 0),
    );

    final match = _constantTimeEquals(expected, actual);
    if (match) {
      await _storage.delete(_kFailCount);
      await _storage.delete(_kLockedUntil);
      return const PinVerifyResult(ok: true, lockedUntilMs: 0, remainingAttempts: maxFailBeforeLock);
    }

    // 失败累计
    final fails = (int.tryParse(await _storage.read(_kFailCount) ?? '') ?? 0) + 1;
    await _storage.write(_kFailCount, fails.toString());
    if (fails >= maxFailBeforeLock) {
      final until = now + lockoutMs;
      await _storage.write(_kLockedUntil, until.toString());
      await _storage.delete(_kFailCount); // 冷却结束后重新允许尝试
      return PinVerifyResult(ok: false, lockedUntilMs: until, remainingAttempts: 0);
    }
    return PinVerifyResult(
      ok: false,
      lockedUntilMs: 0,
      remainingAttempts: maxFailBeforeLock - fails,
    );
  }

  /// 是否启用生物识别快捷解锁（默认 false，首启需用户在设置中打开）
  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(_kBiometricEnabled)) == '1';

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(_kBiometricEnabled, enabled ? '1' : '0');
  }

  /// 重置所有 PIN 相关状态（忘记 PIN / 恢复出厂）
  Future<void> clear() async {
    await _storage.delete(_kCredential); // v2
    await _storage.delete(_kSalt);       // v1 兼容清理
    await _storage.delete(_kHash);       // v1 兼容清理
    await _storage.delete(_kBiometricEnabled);
    await _storage.delete(_kFailCount);
    await _storage.delete(_kLockedUntil);
  }

  // ── internal ─────────────────────────────────────────────
  void _validateFormat(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('PIN length must be 4..8 digits');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw ArgumentError('PIN must be numeric');
    }
  }

  Uint8List _generateSalt(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PIN 校验结果
class PinVerifyResult {
  const PinVerifyResult({
    required this.ok,
    required this.lockedUntilMs,
    required this.remainingAttempts,
  });

  /// 是否通过
  final bool ok;

  /// 若 >0 表示目前处于冷却期的结束时间戳
  final int lockedUntilMs;

  /// 触发冷却前剩余尝试次数
  final int remainingAttempts;

  bool get isLocked => lockedUntilMs > DateTime.now().millisecondsSinceEpoch;

  /// 凭证损坏（非锁定、非普通失败）：remainingAttempts == -1 时表示存储已损坏。
  bool get isCredentialCorrupted => remainingAttempts == -1;
}
