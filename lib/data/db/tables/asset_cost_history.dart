import 'package:drift/drift.dart';

import 'assets.dart';

/// AssetCostHistory: 资产成本价 / 持仓数量调整快照。
///
/// 定位：**用户调仓审计日志**。每次用户在编辑页修改 `costPrice` 或
/// `quantity`（且与上一条记录不同）时写入一条。
///
/// 字段与写入语义：
/// - `costPrice` / `quantity` 均以 [Decimal] 字符串存；金额不走 double。
/// - `currency`：资产币种快照，便于脱离当前 Asset 独立解读历史值。
/// - `source`：`'manual'` 为用户直接编辑；未来若有导入/平账流程可扩展。
/// - `reason`：可选备注（如「加仓」/「分红后成本调整」），UI 可填可不填。
/// - `sourceKey`：`{assetId}:{isoTime}`，UNIQUE，毫秒级时间戳作区分，
///   保证同一 UI 提交只产生一条。
@DataClassName('AssetCostHistoryRow')
class AssetCostHistory extends Table {
  TextColumn get id => text()();
  TextColumn get assetId =>
      text().named('asset_id').references(Assets, #id)();
  TextColumn get costPrice => text().named('cost_price').nullable()();
  TextColumn get quantity => text()();
  TextColumn get currency => text()();
  TextColumn get source => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get triggerTime => dateTime().named('trigger_time')();
  TextColumn get sourceKey => text().named('source_key').nullable().unique()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
