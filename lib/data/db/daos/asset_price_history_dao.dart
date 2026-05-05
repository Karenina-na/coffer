import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/asset_price_history.dart';

part 'asset_price_history_dao.g.dart';

@DriftAccessor(tables: [AssetPriceHistory])
class AssetPriceHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$AssetPriceHistoryDaoMixin {
  AssetPriceHistoryDao(super.db);

  Stream<List<AssetPriceHistoryRow>> watchByAsset(String assetId) {
    return (select(assetPriceHistory)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.triggerTime,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<List<AssetPriceHistoryRow>> listRecent({int limit = 5000}) {
    return (select(assetPriceHistory)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.triggerTime,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<AssetPriceHistoryRow>> listForTrend({
    DateTime? since,
    Set<String>? assetIds,
  }) {
    if (assetIds != null && assetIds.isEmpty) {
      return Future.value(const <AssetPriceHistoryRow>[]);
    }

    final query = select(assetPriceHistory);
    if (since != null) {
      query.where((t) => t.triggerTime.isBiggerOrEqualValue(since));
    }
    if (assetIds != null) {
      query.where((t) => t.assetId.isIn(assetIds.toList(growable: false)));
    }
    query.orderBy([
      (t) => OrderingTerm(
            expression: t.triggerTime,
            mode: OrderingMode.asc,
          ),
    ]);
    return query.get();
  }

  Future<AssetPriceHistoryRow?> findBySourceKey(String key) {
    return (select(assetPriceHistory)..where((t) => t.sourceKey.equals(key)))
        .getSingleOrNull();
  }

  Future<AssetPriceHistoryRow?> latestForAsset(String assetId) {
    return (select(assetPriceHistory)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.triggerTime,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> insertRow(AssetPriceHistoryCompanion row) async {
    await into(assetPriceHistory).insert(row);
  }

  Future<AssetPriceHistoryRow> upsertBySourceKey(
    AssetPriceHistoryCompanion row,
  ) async {
    final rawKey = row.sourceKey.present ? row.sourceKey.value : null;
    final effectiveKey = (rawKey == null || rawKey.isEmpty) ? null : rawKey;
    final normalized = effectiveKey == null
        ? row.copyWith(sourceKey: const Value(null))
        : row;

    return transaction(() async {
      await into(assetPriceHistory)
          .insert(normalized, mode: InsertMode.insertOrIgnore);

      final saved = effectiveKey != null
          ? await (select(assetPriceHistory)
                ..where((t) => t.sourceKey.equals(effectiveKey)))
              .getSingleOrNull()
          : await (select(assetPriceHistory)
                ..where((t) => t.id.equals(row.id.value)))
              .getSingleOrNull();

      if (saved == null) {
        throw StateError(
          'upsertBySourceKey: row not found after insertOrIgnore '
          '(sourceKey=$effectiveKey)',
        );
      }
      return saved;
    });
  }
}
