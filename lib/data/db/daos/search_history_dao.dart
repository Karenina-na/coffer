import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/search_history_entries.dart';

part 'search_history_dao.g.dart';

@DriftAccessor(tables: [SearchHistoryEntries])
class SearchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.db);

  static const queryKind = 'QUERY';
  static const visitKind = 'VISIT';

  Future<List<SearchHistoryEntryRow>> listQueries({int limit = 8}) {
    return (select(searchHistoryEntries)
          ..where((t) => t.kind.equals(queryKind))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<SearchHistoryEntryRow>> listVisits({int limit = 10}) {
    return (select(searchHistoryEntries)
          ..where((t) => t.kind.equals(visitKind))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
  }

  Future<SearchHistoryEntryRow?> findByUniqueKey(String uniqueKey) {
    return (select(searchHistoryEntries)
          ..where((t) => t.uniqueKey.equals(uniqueKey)))
        .getSingleOrNull();
  }

  Future<void> upsertQuery({
    required String query,
    required String normalized,
    required DateTime now,
  }) async {
    final key = 'Q:$normalized';
    final existing = await findByUniqueKey(key);
    if (existing == null) {
      await into(searchHistoryEntries).insert(
        SearchHistoryEntriesCompanion.insert(
          kind: queryKind,
          uniqueKey: key,
          query: Value(query),
          visitedAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(searchHistoryEntries)..where((t) => t.id.equals(existing.id)))
          .write(
        SearchHistoryEntriesCompanion(
          query: Value(query),
          visitedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
    await pruneKind(kind: queryKind, keep: 8);
  }

  Future<void> upsertVisit({
    required String feature,
    required String targetId,
    required String label,
    String? sublabel,
    required DateTime visitedAt,
  }) async {
    final key = 'V:$feature:$targetId';
    final existing = await findByUniqueKey(key);
    if (existing == null) {
      await into(searchHistoryEntries).insert(
        SearchHistoryEntriesCompanion.insert(
          kind: visitKind,
          uniqueKey: key,
          feature: Value(feature),
          targetId: Value(targetId),
          label: Value(label),
          sublabel: Value(sublabel),
          visitedAt: visitedAt,
          updatedAt: visitedAt,
        ),
      );
    } else {
      await (update(searchHistoryEntries)..where((t) => t.id.equals(existing.id)))
          .write(
        SearchHistoryEntriesCompanion(
          feature: Value(feature),
          targetId: Value(targetId),
          label: Value(label),
          sublabel: Value(sublabel),
          visitedAt: Value(visitedAt),
          updatedAt: Value(visitedAt),
        ),
      );
    }
    await pruneKind(kind: visitKind, keep: 10);
  }

  Future<int> clearQueries() {
    return (delete(searchHistoryEntries)..where((t) => t.kind.equals(queryKind))).go();
  }

  Future<void> pruneKind({required String kind, required int keep}) async {
    final rows = await (select(searchHistoryEntries)
          ..where((t) => t.kind.equals(kind))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    if (rows.length <= keep) return;
    final idsToDelete = rows.skip(keep).map((e) => e.id).toList(growable: false);
    await (delete(searchHistoryEntries)..where((t) => t.id.isIn(idsToDelete))).go();
  }
}
