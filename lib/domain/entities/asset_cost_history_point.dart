import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_cost_history_point.freezed.dart';

/// 单次资产成本/数量调整快照。
///
/// 对应 `asset_cost_history` 行；所有金额/数量走 [Decimal]，禁止 double。
/// `sourceKey` 幂等键：`{assetId}:{isoTime}`。
@freezed
abstract class AssetCostHistoryPoint with _$AssetCostHistoryPoint {
  const factory AssetCostHistoryPoint({
    required String id,
    required String assetId,
    Decimal? costPrice,
    required Decimal quantity,
    required String currency,
    required String source,
    String? reason,
    required DateTime triggerTime,
    String? sourceKey,
    required DateTime createdAt,
  }) = _AssetCostHistoryPoint;
}
