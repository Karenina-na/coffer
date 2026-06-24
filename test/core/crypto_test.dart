import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/crypto/field_cipher.dart';
import 'package:coffer/core/crypto/key_derivation.dart';
import 'package:coffer/core/crypto/secure_key_store.dart';
import 'package:coffer/core/errors.dart';

void main() {
  group('FieldCipher', () {
    final cipher = FieldCipher();

    test('round-trip encrypt/decrypt preserves plaintext', () async {
      final key = await AesGcm.with256bits().newSecretKey();
      const plain = '6225 1234 5678 9010';

      final encrypted = await cipher.encryptString(plain, key);
      expect(encrypted.isOk, isTrue);

      final decrypted = await cipher.decryptString(encrypted.valueOrNull!, key);
      expect(decrypted.valueOrNull, plain);
    });

    test('wrong key yields CryptoError', () async {
      final algo = AesGcm.with256bits();
      final k1 = await algo.newSecretKey();
      final k2 = await algo.newSecretKey();

      final encrypted = await cipher.encryptString('secret', k1);
      final decrypted = await cipher.decryptString(encrypted.valueOrNull!, k2);
      expect(decrypted.isErr, isTrue);
      expect(decrypted.errorOrNull, isA<CryptoError>());
    });
  });

  group('SecureKeyStore', () {
    test('损坏 master key 不会静默重建', () async {
      const storage = FlutterSecureStorage();
      FlutterSecureStorage.setMockInitialValues({
        'coffer.master_key.v1': 'not-base64',
      });
      final store = SecureKeyStore(storage: storage);

      await expectLater(
        store.loadOrCreateMaster(),
        throwsA(isA<CryptoError>()),
      );
      expect(await storage.read(key: 'coffer.master_key.v1'), 'not-base64');
    });
  });

  group('KeyDerivation', () {
    test('different purposes derive distinct keys from same master', () async {
      final master = await AesGcm.with256bits().newSecretKey();
      final kd = KeyDerivation();

      final k1 = await kd.derive(master: master, purpose: 'field.card_no');
      final k2 = await kd.derive(master: master, purpose: 'field.cvv');

      final b1 = await k1.extractBytes();
      final b2 = await k2.extractBytes();
      expect(b1, isNot(equals(b2)));
      expect(b1.length, 32);
    });

    test('same purpose + master reproduces the same key', () async {
      final master = await AesGcm.with256bits().newSecretKey();
      final kd = KeyDerivation();
      final a = await (await kd.derive(
        master: master,
        purpose: 'db.sqlcipher',
      )).extractBytes();
      final b = await (await kd.derive(
        master: master,
        purpose: 'db.sqlcipher',
      )).extractBytes();
      expect(a, equals(b));
    });
  });
}
