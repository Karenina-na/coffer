import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_enums.dart';
import '../../domain/repositories/account_repository.dart';
import '../db/daos/account_dao.dart';
import '../db/daos/account_mapper.dart';

/// AccountRepository 的 Drift 实现。
class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(
    this._dao, {
    AccountMapper mapper = const AccountMapper(),
    DateTime Function()? now,
  }) : _mapper = mapper,
       _now = now ?? DateTime.now;

  final AccountDao _dao;
  final AccountMapper _mapper;
  final DateTime Function() _now;

  @override
  Stream<List<Account>> watchAll() {
    return _dao.watchActive().map(
      (rows) => rows.map(_mapper.toDomain).toList(growable: false),
    );
  }

  @override
  Stream<Account?> watchById(String id) => _dao
      .watchById(id)
      .map((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<Result<Account, AppError>> findById(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) return Err(NotFoundError('account not found: $id'));
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('findById failed: $e'));
    }
  }

  @override
  Future<Result<Account, AppError>> create(Account account) async {
    try {
      await _dao.insertRow(_mapper.toInsert(account));
      return Ok(account);
    } catch (e) {
      return Err(StorageError('create failed: $e'));
    }
  }

  @override
  Future<Result<Account, AppError>> update(Account account) async {
    try {
      final updated = account.copyWith(updatedAt: _now());
      final ok = await _dao.replaceRow(_mapper.toInsert(updated));
      if (!ok) {
        return Err(NotFoundError('account not found: ${account.id}'));
      }
      return Ok(updated);
    } catch (e) {
      return Err(StorageError('update failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateStatus(
    String id,
    AccountStatus status,
  ) async {
    try {
      final n = await _dao.updateStatus(
        id: id,
        status: status.code,
        updatedAt: _now(),
      );
      if (n == 0) return Err(NotFoundError('account not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('updateStatus failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) async {
    try {
      final n = await _dao.softDelete(id, _now());
      if (n == 0) return Err(NotFoundError('account not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('softDelete failed: $e'));
    }
  }
}
