import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/watched_pairs.dart';

part 'watched_pair_dao.g.dart';

@DriftAccessor(tables: [WatchedPairs])
class WatchedPairDao extends DatabaseAccessor<AppDatabase>
    with _$WatchedPairDaoMixin {
  WatchedPairDao(super.db);

  Stream<List<WatchedPairRow>> watchAll() {
    return (select(watchedPairs)
          ..orderBy([(t) => OrderingTerm.asc(t.pairKey)]))
        .watch();
  }

  Future<List<WatchedPairRow>> listAll() {
    return (select(watchedPairs)
          ..orderBy([(t) => OrderingTerm.asc(t.pairKey)]))
        .get();
  }

  Future<void> upsert(WatchedPairsCompanion row) async {
    await into(watchedPairs).insertOnConflictUpdate(row);
  }

  Future<int> deleteByKey(String pairKey) {
    return (delete(watchedPairs)..where((t) => t.pairKey.equals(pairKey))).go();
  }

  Future<int> updateThresholds({
    required String pairKey,
    required String? thresholdHigh,
    required String? thresholdLow,
    required String? alertChangePct,
  }) {
    return (update(watchedPairs)..where((t) => t.pairKey.equals(pairKey)))
        .write(WatchedPairsCompanion(
      thresholdHigh: Value(thresholdHigh),
      thresholdLow: Value(thresholdLow),
      alertChangePct: Value(alertChangePct),
    ));
  }
}
