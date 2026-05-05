import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 从主密钥派生用途独立的子密钥（HKDF-SHA256）。
///
/// 用途字符串（`info`）固定：
/// - `"db.sqlcipher"`：SQLCipher 整库加密密钥
/// - `"field.card_no"`：卡号字段加密密钥
/// - `"field.cvv"`：CVV 字段加密密钥
/// - `"backup.payload"`：备份导出加密密钥
class KeyDerivation {
  KeyDerivation({Hkdf? hkdf})
      : _hkdf = hkdf ?? Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  final Hkdf _hkdf;

  Future<SecretKey> derive({
    required SecretKey master,
    required String purpose,
    List<int> salt = const [],
  }) {
    return _hkdf.deriveKey(
      secretKey: master,
      info: utf8.encode(purpose),
      nonce: salt,
    );
  }

  /// 将 [SecretKey] 导出为 Base64 字符串（用于 SQLCipher 等需明文密钥场景）。
  static Future<String> exportBase64(SecretKey key) async {
    final bytes = await key.extractBytes();
    return base64Encode(Uint8List.fromList(bytes));
  }
}
