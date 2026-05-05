import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/asset_price_history_point.dart';
import '../../domain/repositories/asset_price_history_repository.dart';
import '../db/daos/asset_price_history_dao.dart';
import '../db/daos/asset_price_history_mapper.dart';

class DriftAssetPriceHistoryRepository implements AssetPriceHistoryRepository {
  DriftAssetPriceHistoryRepository(
    this._dao, {
    AssetPriceHistoryMapper mapper = const AssetPriceHistoryMapper(),
  }) : _mapper = mapper;

  final AssetPriceHistoryDao _dao;
  final AssetPriceHistoryMapper _mapper;

  @override
  Stream<List<AssetPriceHistoryPoint>> watchByAsset(String assetId) {
    return _dao.watchByAsset(assetId).map(
          (rows) => rows.map(_mapper.toDomain).toList(growable: false),
        );
  }

  @override
  Future<List<AssetPriceHistoryPoint>> listRecent({int limit = 5000}) async {
    try {
      final rows = await _dao.listRecent(limit: limit);
      return rows.map(_mapper.toDomain).toList(growable: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('drift_asset_price_history: listRecent failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<List<AssetPriceHistoryPoint>> listForTrend({
    DateTime? since,
    Set<String>? assetIds,
  }) async {
    try {
      final rows = await _dao.listForTrend(since: since, assetIds: assetIds);
      return rows.map(_mapper.toDomain).toList(growable: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('drift_asset_price_history: listForTrend failed: $e\n$st');
      return const [];
    }
  }

  @override
  Future<Result<AssetPriceHistoryPoint, AppError>> record(
    AssetPriceHistoryPoint point,
  ) async {
    try {
      final saved = await _dao.upsertBySourceKey(_mapper.toInsert(point));
      return Ok(_mapper.toDomain(saved));
    } catch (e) {
      return Err(StorageError('record price history failed: $e'));
    }
  }

  @override
  Future<DateTime?> latestTriggerTimeForAsset(String assetId) async {
    try {
      final row = await _dao.latestForAsset(assetId);
      return row?.triggerTime;
    } catch (e, st) {
      if (kDebugMode) debugPrint('drift_asset_price_history: latestTriggerTimeForAsset failed: $e\n$st');
      return null;
    }
  }
}
