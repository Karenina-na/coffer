import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../core/crypto/field_cipher.dart';
import '../../core/crypto/key_derivation.dart';
import '../../core/crypto/secure_key_store.dart';

class SearchHistoryProtector {
  SearchHistoryProtector({
    SecureKeyStore? keyStore,
    KeyDerivation? keyDerivation,
    FieldCipher? fieldCipher,
    Future<SecretKey> Function()? masterKeyLoader,
  }) : _keyStore = keyStore ?? SecureKeyStore(),
       _kdf = keyDerivation ?? KeyDerivation(),
       _cipher = fieldCipher ?? FieldCipher(),
       _masterKeyLoader = masterKeyLoader;

  static const purpose = 'app.search_history';

  final SecureKeyStore _keyStore;
  final KeyDerivation _kdf;
  final FieldCipher _cipher;
  final Future<SecretKey> Function()? _masterKeyLoader;

  SecretKey? _derived;

  Future<SecretKey> _key() async {
    final cached = _derived;
    if (cached != null) return cached;
    final master =
        await (_masterKeyLoader?.call() ?? _keyStore.loadOrCreateMaster());
    final derived = await _kdf.derive(master: master, purpose: purpose);
    _derived = derived;
    return derived;
  }

  Future<String?> encode(Map<String, dynamic> payload) async {
    final key = await _key();
    final encoded = jsonEncode(payload);
    final result = await _cipher.encryptString(encoded, key);
    return result.valueOrNull;
  }

  Future<Map<String, dynamic>?> decode(String ciphertext) async {
    final key = await _key();
    final result = await _cipher.decryptString(ciphertext, key);
    final plain = result.valueOrNull;
    if (plain == null) return null;
    final decoded = jsonDecode(plain);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}
