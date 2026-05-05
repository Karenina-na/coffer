import 'package:drift/drift.dart';

import 'assets.dart';

/// AssetPriceHistory: 资产估值快照（独立于领域事件表）。
///
/// 定位：**审计日志 / 行情时序**，不是用户要处理的事件。
/// 在方案 B 中，同步成功的估值写入此表，不再污染 `events`；
/// 后者仅保留真正需要用户感知的告警（失败、同步过期等）。
///
/// 字段与写入语义：
/// - `sourceKey` 格式 `{assetId}:{yyyymmdd}:{source}`，UNIQUE，
///   同一资产同一天同一数据源只保留一条，重复 sync 幂等
/// - `price` / `marketValue` 均为 `Decimal` 字符串，金额不走 double
/// - `rawPayload` JSON，保留 symbol 等附加信息以供调试
@DataClassName('AssetPriceHistoryRow')
class AssetPriceHistory extends Table {
  TextColumn get id => text()();
  TextColumn get assetId =>
      text().named('asset_id').references(Assets, #id)();
  TextColumn get price => text()();
  TextColumn get marketValue => text().named('market_value').nullable()();
  TextColumn get currency => text()();
  TextColumn get source => text()();
  TextColumn get batchId => text().named('batch_id').nullable()();
  DateTimeColumn get triggerTime => dateTime().named('trigger_time')();
  TextColumn get sourceKey => text().named('source_key').nullable().unique()();
  TextColumn get rawPayload => text().named('raw_payload').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
