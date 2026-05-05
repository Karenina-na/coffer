import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/asset_cost_history_point.dart';
import '../../domain/repositories/asset_cost_history_repository.dart';
import '../db/daos/asset_cost_history_dao.dart';
import '../db/daos/asset_cost_history_mapper.dart';

class DriftAssetCostHistoryRepository implements AssetCostHistoryRepository {
  DriftAssetCostHistoryRepository(
    this._dao, {
    AssetCostHistoryMapper mapper = const AssetCostHistoryMapper(),
  }) : _mapper = mapper;

  final AssetCostHistoryDao _dao;
  final AssetCostHistoryMapper _mapper;

  @override
  Stream<List<AssetCostHistoryPoint>> watchByAsset(String assetId) =>
      _dao.watchByAsset(assetId).map(
          (rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Future<List<AssetCostHistoryPoint>> listByAsset(String assetId) async {
    final rows = await _dao.listByAsset(assetId);
    return rows.map(_mapper.toDomain).toList(growable: false);
  }

  @override
  Future<Result<AssetCostHistoryPoint, AppError>> record(
      AssetCostHistoryPoint p) async {
    try {
      // 通过 DAO 层原子 upsert 保证幂等：若 sourceKey 已存在直接返回既有行，
      // 否则写入新行；sourceKey 为空时退化为普通 insert（不去重）。
      final row = await _dao.upsertBySourceKey(_mapper.toInsert(p));
      return Ok(_mapper.toDomain(row));
    } on Exception catch (e, st) {
      return Err(StorageError('record cost history failed: $e\n$st'));
    }
  }

  @override
  Future<AssetCostHistoryPoint?> latestForAsset(String assetId) async {
    final r = await _dao.latestForAsset(assetId);
    return r == null ? null : _mapper.toDomain(r);
  }
}
