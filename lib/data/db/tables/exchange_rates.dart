import 'package:drift/drift.dart';

/// ExchangeRate: 汇率快照。
///
/// See doc/data-definitions.md §6.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get id => text()();
  TextColumn get pairKey => text().named('pair_key')();
  TextColumn get baseCurrency => text().named('base_currency')();
  TextColumn get quoteCurrency => text().named('quote_currency')();
  TextColumn get rate => text()();
  DateTimeColumn get asOfTime => dateTime().named('as_of_time')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get source => text()();
  TextColumn get snapshotType => text().named('snapshot_type')();
  TextColumn get rawPayload => text().named('raw_payload').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
