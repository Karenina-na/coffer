import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/card_enums.dart';
import '../../domain/repositories/card_repository.dart';
import '../crypto_service.dart';
import '../db/daos/card_dao.dart';
import '../db/daos/card_mapper.dart';

class DriftCardRepository implements CardRepository {
  DriftCardRepository(
    this._dao,
    this._crypto, {
    CardMapper mapper = const CardMapper(),
    DateTime Function()? now,
  })  : _mapper = mapper,
        _now = now ?? DateTime.now;

  final CardDao _dao;
  final CryptoService _crypto;
  final CardMapper _mapper;
  final DateTime Function() _now;

  @override
  Stream<List<BankCard>> watchAll() => _dao
      .watchAll()
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<List<BankCard>> watchByAccount(String accountId) => _dao
      .watchByAccount(accountId)
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Future<Result<BankCard, AppError>> findById(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) return Err(NotFoundError('card not found: $id'));
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('findById failed: $e'));
    }
  }

  @override
  Future<Result<BankCard, AppError>> create({
    required BankCard card,
    String? plainCardNo,
    String? plainCvv,
  }) async {
    try {
      String? cardCt = card.cardNoCiphertext;
      if (plainCardNo != null) {
        final r = await _crypto.encryptField(
          purpose: CryptoPurpose.cardNo,
          plaintext: plainCardNo,
        );
        if (r.isErr) return Err(r.errorOrNull!);
        cardCt = r.valueOrNull;
      }
      String? cvvCt = card.cvvCiphertext;
      if (plainCvv != null) {
        final r = await _crypto.encryptField(
          purpose: CryptoPurpose.cvv,
          plaintext: plainCvv,
        );
        if (r.isErr) return Err(r.errorOrNull!);
        cvvCt = r.valueOrNull;
      }
      final toStore = card.copyWith(
        cardNoCiphertext: cardCt,
        cvvCiphertext: cvvCt,
      );
      await _dao.insertRow(_mapper.toInsert(toStore));
      return Ok(toStore);
    } catch (e) {
      return Err(StorageError('create failed: $e'));
    }
  }

  @override
  Future<Result<BankCard, AppError>> update({
    required BankCard card,
    String? plainCardNo,
    String? plainCvv,
  }) async {
    try {
      String? cardCt = card.cardNoCiphertext;
      if (plainCardNo != null) {
        final r = await _crypto.encryptField(
          purpose: CryptoPurpose.cardNo,
          plaintext: plainCardNo,
        );
        if (r.isErr) return Err(r.errorOrNull!);
        cardCt = r.valueOrNull;
      }
      String? cvvCt = card.cvvCiphertext;
      if (plainCvv != null) {
        final r = await _crypto.encryptField(
          purpose: CryptoPurpose.cvv,
          plaintext: plainCvv,
        );
        if (r.isErr) return Err(r.errorOrNull!);
        cvvCt = r.valueOrNull;
      }
      final toStore = card.copyWith(
        cardNoCiphertext: cardCt,
        cvvCiphertext: cvvCt,
        updatedAt: _now(),
      );
      final ok = await _dao.replaceRow(_mapper.toUpdate(toStore));
      if (!ok) return Err(NotFoundError('card not found: ${card.id}'));
      return Ok(toStore);
    } catch (e) {
      return Err(StorageError('update failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateStatus(
    String id,
    CardStatus status,
  ) async {
    try {
      final n = await _dao.updateStatus(
        id: id,
        status: status.code,
        updatedAt: _now(),
      );
      if (n == 0) return Err(NotFoundError('card not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('updateStatus failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    try {
      final n = await _dao.deleteById(id);
      if (n == 0) return Err(NotFoundError('card not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('delete failed: $e'));
    }
  }

  @override
  Future<Result<String, AppError>> decryptCardNo(String id) =>
      _decrypt(id, CryptoPurpose.cardNo, (c) => c.cardNoCiphertext);

  @override
  Future<Result<String, AppError>> decryptCvv(String id) =>
      _decrypt(id, CryptoPurpose.cvv, (c) => c.cvvCiphertext);

  Future<Result<String, AppError>> _decrypt(
    String id,
    String purpose,
    String? Function(BankCard) ciphertextOf,
  ) async {
    final found = await findById(id);
    if (found.isErr) return Err(found.errorOrNull!);
    final ct = ciphertextOf(found.valueOrNull!);
    if (ct == null) return const Err(NotFoundError('ciphertext missing'));
    return _crypto.decryptField(purpose: purpose, ciphertext: ct);
  }
}
