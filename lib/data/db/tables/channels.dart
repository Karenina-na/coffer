import 'package:drift/drift.dart';

/// Channel: 转账网络/协议定义（不与 Account 建立外键）。
///
/// See doc/data-definitions.md §4.
@DataClassName('ChannelRow')
class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get transferProtocol => text().named('transfer_protocol')();
  BoolColumn get isBuiltin =>
      boolean().named('is_builtin').withDefault(const Constant(false))();
  TextColumn get feeRate => text().named('fee_rate').nullable()();
  TextColumn get fixedFee => text().named('fixed_fee').nullable()();
  TextColumn get sovereigntyRegionRule =>
      text().named('sovereignty_region_rule').nullable()();
  TextColumn get limitCurrency => text().named('limit_currency').nullable()();
  TextColumn get dailyLimit => text().named('daily_limit').nullable()();
  TextColumn get singleLimit => text().named('single_limit').nullable()();
  TextColumn get status => text()();
  DateTimeColumn get effectiveFrom =>
      dateTime().named('effective_from').nullable()();
  DateTimeColumn get effectiveTo =>
      dateTime().named('effective_to').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
