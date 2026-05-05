import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_price_history_point.freezed.dart';

/// 单次资产估值快照。
///
/// 对应 `asset_price_history` 行；所有金额走 [Decimal]，禁止 double。
/// `sourceKey` 用于幂等：`{assetId}:{yyyymmdd}:{source}`。
@freezed
abstract class AssetPriceHistoryPoint with _$AssetPriceHistoryPoint {
  const factory AssetPriceHistoryPoint({
    required String id,
    required String assetId,
    required Decimal price,
    Decimal? marketValue,
    required String currency,
    required String source,
    String? batchId,
    required DateTime triggerTime,
    String? sourceKey,
    String? rawPayload,
    required DateTime createdAt,
  }) = _AssetPriceHistoryPoint;
}
