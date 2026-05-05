import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_enums.dart';
import '../../domain/repositories/asset_repository.dart';
import '../db/daos/asset_dao.dart';
import '../db/daos/asset_mapper.dart';

class DriftAssetRepository implements AssetRepository {
  DriftAssetRepository(
    this._dao, {
    AssetMapper mapper = const AssetMapper(),
    DateTime Function()? now,
  }) : _mapper = mapper,
       _now = now ?? DateTime.now;

  final AssetDao _dao;
  final AssetMapper _mapper;
  final DateTime Function() _now;

  @override
  Stream<List<Asset>> watchAll() => _dao.watchActive().map(
    (rows) => rows.map(_mapper.toDomain).toList(growable: false),
  );

  @override
  Stream<List<Asset>> watchByAccount(String accountId) => _dao
      .watchByAccount(accountId)
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<Asset?> watchById(String id) => _dao
      .watchById(id)
      .map((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<Result<Asset, AppError>> findById(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) return Err(NotFoundError('asset not found: $id'));
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('findById failed: $e'));
    }
  }

  @override
  Future<Result<Asset, AppError>> create(Asset asset) async {
    try {
      await _dao.insertRow(_mapper.toInsert(asset));
      // 读回 DB 最新状态，确保返回 DB 可能补填的字段（如 updatedAt）。
      // 使用 findByIdAny 以包含调用方显式传入 isDeleted=true 的行。
      final row = await _dao.findByIdAny(asset.id);
      if (row == null) {
        return Err(StorageError('create succeeded but re-read failed: ${asset.id}'));
      }
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('create failed: $e'));
    }
  }

  @override
  Future<Result<Asset, AppError>> update(Asset asset) async {
    try {
      final updated = asset.copyWith(updatedAt: _now());
      final ok = await _dao.replaceRow(_mapper.toInsert(updated));
      if (!ok) return Err(NotFoundError('asset not found: ${asset.id}'));
      return Ok(updated);
    } catch (e) {
      return Err(StorageError('update failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateStatus(
    String id,
    AssetStatus status,
  ) async {
    try {
      final n = await _dao.updateStatus(
        id: id,
        status: status.code,
        updatedAt: _now(),
      );
      if (n == 0) return Err(NotFoundError('asset not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('updateStatus failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) async {
    try {
      final n = await _dao.softDelete(id, _now());
      if (n == 0) return Err(NotFoundError('asset not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('softDelete failed: $e'));
    }
  }
}
