import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors.dart';

/// 主密钥存储：首次启动生成 32 字节随机主密钥，加密保存到平台 Keystore。
///
/// - iOS：Keychain（`first_unlock_this_device`）
/// - Android：EncryptedSharedPreferences（AES 硬件支持时走 StrongBox）
///
/// 调用方通过 [KeyDerivation] 派生出用途子密钥，绝不直接暴露主密钥。
class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            aOptions: AndroidOptions(),
          ),
      _random = random ?? Random.secure();

  static const _masterKeyAlias = 'gwp.master_key.v1';
  static const _masterKeyBytes = 32;

  final FlutterSecureStorage _storage;
  final Random _random;

  /// 读取主密钥；若不存在则新建并持久化。
  ///
  /// 如果 Keystore 里存在旧值但无法解码或长度不等于 [_masterKeyBytes]，
  /// 视为主密钥损坏并抛出 [CryptoError]。只有首次安装时的空值才会生成新 key，
  /// 避免 Keystore 异常 / 迁移失败时静默覆写导致旧数据不可恢复。
  ///
  /// 安全检查：若数据库文件已存在但主密钥丢失（Keystore 被 OS 清空），
  /// 抛出 [CryptoError] 而非生成新密钥，避免旧数据永久不可解密。
  Future<SecretKey> loadOrCreateMaster() async {
    String? existing;
    try {
      existing = await _storage.read(key: _masterKeyAlias);
    } catch (e) {
      throw CryptoError('failed to read master key from Keystore: $e');
    }
    if (existing != null) {
      final decoded = _decodeExistingMaster(existing);
      return SecretKey(decoded);
    }
    // 主密钥不存在：检查数据库文件是否已存在。
    // 若已存在，说明 Keystore 被 OS 清空（系统升级/恢复出厂），此时生成新密钥
    // 会导致旧加密数据永久不可解密——应抛出异常让用户走恢复流程。
    if (await _databaseFileExists()) {
      throw const CryptoError(
        'master key lost but encrypted database exists — '
        'data recovery required. Reinstall the app or restore from backup.',
      );
    }
    final bytes = Uint8List(_masterKeyBytes);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    try {
      await _storage.write(key: _masterKeyAlias, value: base64Encode(bytes));
    } catch (e) {
      throw CryptoError('failed to persist master key: $e');
    }
    return SecretKey(bytes);
  }

  /// 检查加密数据库文件是否已存在。
  Future<bool> _databaseFileExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, 'gwp.db')).exists();
    } catch (_) {
      return false;
    }
  }

  Uint8List _decodeExistingMaster(String existing) {
    try {
      final decoded = base64Decode(existing);
      if (decoded.length != _masterKeyBytes) {
        throw const CryptoError('master key corrupted: invalid length');
      }
      return Uint8List.fromList(decoded);
    } on FormatException {
      throw const CryptoError('master key corrupted: invalid base64');
    }
  }

  /// 仅在「忘记密码/重置」流程中调用；会让旧库彻底无法解密。
  Future<void> destroyMaster() async {
    await _storage.delete(key: _masterKeyAlias);
  }
}
