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
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<CardRow>> watchByAccount(String accountId) {
    return (select(cards)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
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
}
