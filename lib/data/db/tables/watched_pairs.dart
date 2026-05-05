import 'package:drift/drift.dart';

/// WatchedCurrencyPairs: 用户关注的币对列表，驱动汇率批量拉取 + 预警。
///
/// 设计：以 `pair_key`（形如 `USD/CNY`）作为主键，保证同一币对只有一条订阅。
///
/// v9 起增加三个可选预警阈值：
/// - `threshold_high` / `threshold_low`：绝对值阈值，最新汇率穿越即报警。
/// - `alert_change_pct`：相对上一期（近 2 天）波动百分比阈值（如 3.0 表示
///   ±3%），超过绝对值即报警。
/// 任一字段为 NULL 表示该维度未开启预警。
///
/// v12 起三个阈值列均以 TEXT 形式保存 Decimal 字符串，杜绝 double 精度漂移。
@DataClassName('WatchedPairRow')
class WatchedPairs extends Table {
  TextColumn get pairKey => text().named('pair_key')();
  TextColumn get baseCurrency => text().named('base_currency')();
  TextColumn get quoteCurrency => text().named('quote_currency')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get thresholdHigh =>
      text().named('threshold_high').nullable()();
  TextColumn get thresholdLow =>
      text().named('threshold_low').nullable()();
  TextColumn get alertChangePct =>
      text().named('alert_change_pct').nullable()();

  @override
  Set<Column> get primaryKey => {pairKey};
}
