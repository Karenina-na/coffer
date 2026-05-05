import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../errors.dart';
import '../result.dart';

/// 字段级加密封装，使用 AES-GCM 256。
///
/// 设计要点：
/// - 明文仅以 [String] 或 [Uint8List] 形式在内存中短暂存在
/// - 密文采用 `nonce || ciphertext || mac` 的紧凑布局，Base64 后入库
/// - 调用方负责密钥派生（见 [KeyDerivation]），本类只负责加/解密
class FieldCipher {
  FieldCipher({AesGcm? algorithm})
      : _algorithm = algorithm ?? AesGcm.with256bits();

  static const int _nonceLength = 12;
  static const int _macLength = 16;

  final AesGcm _algorithm;

  /// 加密 UTF-8 文本字段。
  ///
  /// [aad] 可选的关联数据（Associated Data）。若提供，解密时必须传入完全相同
  /// 的 [aad] 才能通过 MAC 校验，常用于把明文元信息（版本号、KDF 参数等）绑
  /// 定到密文，防止第三方篡改元信息后重放。
  Future<Result<String, AppError>> encryptString(
    String plaintext,
    SecretKey key, {
    List<int>? aad,
  }) async {
    try {
      final box = await _algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        aad: aad ?? const <int>[],
      );
      return Ok(_pack(box));
    } catch (e) {
      return Err(CryptoError('encrypt failed: $e'));
    }
  }

  /// 解密 Base64 密文为 UTF-8 文本。
  ///
  /// 若加密时使用了 [aad]，解密时必须传入等价字节序列，否则 MAC 校验失败。
  Future<Result<String, AppError>> decryptString(
    String ciphertext,
    SecretKey key, {
    List<int>? aad,
  }) async {
    try {
      final box = _unpack(ciphertext);
      final clear = await _algorithm.decrypt(
        box,
        secretKey: key,
        aad: aad ?? const <int>[],
      );
      return Ok(utf8.decode(clear));
    } catch (e) {
      return Err(CryptoError('decrypt failed: $e'));
    }
  }

  String _pack(SecretBox box) {
    final bytes = BytesBuilder(copy: true)
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return base64Encode(bytes.toBytes());
  }

  SecretBox _unpack(String encoded) {
    final raw = base64Decode(encoded);
    if (raw.length < _nonceLength + _macLength) {
      throw const FormatException('ciphertext too short');
    }
    final nonce = raw.sublist(0, _nonceLength);
    final macStart = raw.length - _macLength;
    final cipher = raw.sublist(_nonceLength, macStart);
    final mac = Mac(raw.sublist(macStart));
    return SecretBox(cipher, nonce: nonce, mac: mac);
  }
}
