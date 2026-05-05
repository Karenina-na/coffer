import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset_price_history_point.dart';

/// 资产估值快照仓储。
///
/// 与 [EventRepository] 分离：估值成功走此处（审计型，海量写入不打扰用户），
/// 失败与 `ASSET_SYNC_OUTDATED` 聚合提醒走事件表。
abstract interface class AssetPriceHistoryRepository {
  /// 某资产的全部估值历史，按 triggerTime 升序，供图表消费。
  Stream<List<AssetPriceHistoryPoint>> watchByAsset(String assetId);

  /// 最近若干条估值（按 triggerTime 降序）。
  /// 面向仪表盘净值趋势聚合。
  Future<List<AssetPriceHistoryPoint>> listRecent({int limit = 5000});

  /// 图表聚合用的估值历史，按 triggerTime 升序返回。
  ///
  /// - [assetIds] 为空时返回空列表；null 表示不过滤资产。
  /// - [since] 非空时只返回该时间之后（含边界）的记录。
  Future<List<AssetPriceHistoryPoint>> listForTrend({
    DateTime? since,
    Set<String>? assetIds,
  });

  /// 幂等写入：若 [AssetPriceHistoryPoint.sourceKey] 已存在则返回既有记录。
  Future<Result<AssetPriceHistoryPoint, AppError>> record(
    AssetPriceHistoryPoint point,
  );

  /// 某资产最近一次估值时间；用于「同步是否过期」判定。
  Future<DateTime?> latestTriggerTimeForAsset(String assetId);
}
