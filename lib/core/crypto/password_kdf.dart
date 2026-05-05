import 'package:cryptography/cryptography.dart';

import '../errors.dart';
import '../result.dart';

/// 基于 Argon2id 的口令派生密钥。
///
/// 参数采用 OWASP 建议的移动端档位（64MB / t=3 / p=1）；
/// 调用方需要持久化 [DerivedKey.salt] 以便后续验证。
class PasswordKdf {
  PasswordKdf({
    this.memoryKib = 65536,
    this.iterations = 3,
    this.parallelism = 1,
    this.hashLength = 32,
  }) : assert(memoryKib > 0, 'memoryKib must be positive'),
       assert(iterations > 0, 'iterations must be positive'),
       assert(parallelism > 0, 'parallelism must be positive'),
       assert(hashLength > 0, 'hashLength must be positive');

  final int memoryKib;
  final int iterations;
  final int parallelism;
  final int hashLength;

  Future<Result<SecretKey, AppError>> derive({
    required String password,
    required List<int> salt,
  }) async {
    try {
      final algo = Argon2id(
        parallelism: parallelism,
        memory: memoryKib,
        iterations: iterations,
        hashLength: hashLength,
      );
      final key = await algo.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      return Ok(key);
    } catch (e) {
      return Err(CryptoError('argon2id derive failed: $e'));
    }
  }
}
