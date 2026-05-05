import 'package:cryptography/cryptography.dart';

import '../../core/crypto/field_cipher.dart';
import '../../core/crypto/key_derivation.dart';
import '../../core/crypto/secure_key_store.dart';
import '../../core/errors.dart';
import '../../core/result.dart';

/// 字段加密服务：向上层屏蔽 KeyStore / KeyDerivation / FieldCipher 的编排。
///
/// - 主密钥：惰性加载，进程内缓存
/// - 子密钥：按 purpose 缓存一份 [SecretKey]，避免每次派生
class CryptoService {
  CryptoService({
    SecureKeyStore? keyStore,
    KeyDerivation? keyDerivation,
    FieldCipher? fieldCipher,
  }) : _keyStore = keyStore ?? SecureKeyStore(),
       _kdf = keyDerivation ?? KeyDerivation(),
       _cipher = fieldCipher ?? FieldCipher();

  final SecureKeyStore _keyStore;
  final KeyDerivation _kdf;
  final FieldCipher _cipher;

  SecretKey? _master;
  Future<SecretKey>? _masterFuture;
  final Map<String, SecretKey> _purposeKeys = {};

  Future<SecretKey> _keyFor(String purpose) async {
    final cached = _purposeKeys[purpose];
    if (cached != null) return cached;
    // 失败的 Future 不应被缓存：若 loadOrCreateMaster 抛出异常，
    // 重置 _masterFuture 以便下次重试，避免永久加密失效。
    _masterFuture ??= _keyStore.loadOrCreateMaster().catchError((Object e) {
      _masterFuture = null;
      throw e;
    });
    _master = await _masterFuture;
    final derived = await _kdf.derive(master: _master!, purpose: purpose);
    _purposeKeys[purpose] = derived;
    return derived;
  }

  Future<Result<String, AppError>> encryptField({
    required String purpose,
    required String plaintext,
  }) async {
    try {
      final key = await _keyFor(purpose);
      return _cipher.encryptString(plaintext, key);
    } on AppError catch (e) {
      return Err(e);
    }
  }

  Future<Result<String, AppError>> decryptField({
    required String purpose,
    required String ciphertext,
  }) async {
    try {
      final key = await _keyFor(purpose);
      return _cipher.decryptString(ciphertext, key);
    } on AppError catch (e) {
      return Err(e);
    }
  }

  /// 测试/登出场景：清空进程内缓存的密钥。
  void clearCache() {
    _master = null;
    _masterFuture = null;
    _purposeKeys.clear();
  }
}

/// 固定 purpose，防止字符串散落在各处。
abstract final class CryptoPurpose {
  static const cardNo = 'field.card_no';
  static const cvv = 'field.cvv';
  static const backup = 'backup.payload';
}
