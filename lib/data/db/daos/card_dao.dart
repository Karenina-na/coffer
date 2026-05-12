import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cards.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Stream<List<CardRow>> watchAll() {
    return (select(cards)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Stream<List<CardRow>> watchByAccount(String accountId) {
    return (select(cards)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<CardRow?> findById(String id) {
    return (select(cards)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertRow(CardsCompanion row) async {
    await into(cards).insert(row);
  }

  /// 按主键全量替换一行。返回是否命中一行。
  Future<bool> replaceRow(CardsCompanion row) {
    return update(cards).replace(row);
  }

  Future<int> updateStatus({
    required String id,
    required String status,
    required DateTime updatedAt,
  }) {
    return (update(cards)..where((t) => t.id.equals(id))).write(
      CardsCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> deleteById(String id) {
    return (delete(cards)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateSortOrder({
    required String id,
    required int sortOrder,
    required DateTime updatedAt,
  }) {
    return (update(cards)..where((t) => t.id.equals(id))).write(
      CardsCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
