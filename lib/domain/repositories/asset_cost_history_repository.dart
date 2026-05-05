import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset_cost_history_point.dart';

abstract interface class AssetCostHistoryRepository {
  Stream<List<AssetCostHistoryPoint>> watchByAsset(String assetId);
  Future<List<AssetCostHistoryPoint>> listByAsset(String assetId);
  Future<Result<AssetCostHistoryPoint, AppError>> record(
    AssetCostHistoryPoint point,
  );
  Future<AssetCostHistoryPoint?> latestForAsset(String assetId);
}
