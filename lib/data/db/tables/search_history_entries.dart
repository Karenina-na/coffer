import 'package:drift/drift.dart';

@DataClassName('SearchHistoryEntryRow')
class SearchHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get uniqueKey => text().named('unique_key')();
  TextColumn get query => text().nullable()();
  TextColumn get feature => text().nullable()();
  TextColumn get targetId => text().named('target_id').nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get sublabel => text().nullable()();
  DateTimeColumn get visitedAt => dateTime().named('visited_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
