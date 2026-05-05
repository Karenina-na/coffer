import 'package:drift/drift.dart';

import 'accounts.dart';

/// Asset: 资产持仓。
///
/// See doc/data-definitions.md §3.
/// Decimal(28,8)/(28,10) 字段统一以 TEXT 存储，由应用层以 [Decimal] 解析。
@DataClassName('AssetRow')
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().named('account_id').references(Accounts, #id)();
  TextColumn get assetType => text().named('asset_type')();
  TextColumn get assetCode => text().named('asset_code').nullable()();
  TextColumn get quantity => text()();
  TextColumn get costPrice => text().named('cost_price').nullable()();
  TextColumn get currentPrice => text().named('current_price').nullable()();
  TextColumn get currency => text()();
  TextColumn get marketValue => text().named('market_value').nullable()();
  DateTimeColumn get valuationTime =>
      dateTime().named('valuation_time').nullable()();
  TextColumn get status => text()();
  TextColumn get extInfo => text().named('ext_info').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
