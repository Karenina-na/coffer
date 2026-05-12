import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/channels.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels])
class ChannelDao extends DatabaseAccessor<AppDatabase>
    with _$ChannelDaoMixin {
  ChannelDao(super.db);

  Stream<List<ChannelRow>> watchAll() {
    return (select(channels)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<ChannelRow?> findById(String id) {
    return (select(channels)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(ChannelsCompanion row) async {
    await into(channels).insertOnConflictUpdate(row);
  }

  Future<int> setStatus({
    required String id,
    required String status,
    required DateTime updatedAt,
  }) {
    return (update(channels)..where((t) => t.id.equals(id))).write(
      ChannelsCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> updateSortOrder({
    required String id,
    required int sortOrder,
    required DateTime updatedAt,
  }) {
    return (update(channels)..where((t) => t.id.equals(id))).write(
      ChannelsCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
