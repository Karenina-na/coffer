import 'package:drift/drift.dart';

/// Account: 账户主体。
///
/// See doc/data-definitions.md §2.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get accountNo => text().named('account_no').nullable()();
  TextColumn get accountType => text().named('account_type')();
  TextColumn get sovereigntyRegion => text().named('sovereignty_region')();
  TextColumn get institutionName => text().named('institution_name')();
  TextColumn get status => text()();
  DateTimeColumn get openedAt => dateTime().named('opened_at').nullable()();
  TextColumn get extInfo => text().named('ext_info').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  RealColumn get fxSpreadPercent =>
      real().named('fx_spread_percent').withDefault(const Constant(0.0))();
  TextColumn get fxFixedFee =>
      text().named('fx_fixed_fee').withDefault(const Constant('0'))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
