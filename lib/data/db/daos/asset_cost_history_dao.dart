import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/asset_cost_history.dart';

part 'asset_cost_history_dao.g.dart';

@DriftAccessor(tables: [AssetCostHistory])
class AssetCostHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$AssetCostHistoryDaoMixin {
  AssetCostHistoryDao(super.db);

  Stream<List<AssetCostHistoryRow>> watchByAsset(String assetId) {
    return (select(assetCostHistory)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<AssetCostHistoryRow>> listByAsset(String assetId) {
    return (select(assetCostHistory)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<AssetCostHistoryRow?> findBySourceKey(String key) {
    return (select(assetCostHistory)..where((t) => t.sourceKey.equals(key)))
        .getSingleOrNull();
  }

  Future<AssetCostHistoryRow?> latestForAsset(String assetId) {
    return (select(assetCostHistory)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> insertRow(AssetCostHistoryCompanion row) async {
    await into(assetCostHistory).insert(row);
  }

  /// 幂等插入：若存在相同 sourceKey 的行则跳过 INSERT，返回现有行；
  /// 否则插入并返回新行。
  ///
  /// 通过 `InsertMode.insertOrIgnore` 让 SQLite 侧直接吃掉 UNIQUE 约束冲突，
  /// 避免应用层 check-then-insert 存在的 TOCTOU 竞态窗口。
  ///
  /// 语义：sourceKey 为空字符串视同 null（不参与去重），与旧
  /// `DriftAssetCostHistoryRepository.record()` 的行为保持一致。
  Future<AssetCostHistoryRow> upsertBySourceKey(
      AssetCostHistoryCompanion row) async {
    final rawKey = row.sourceKey.present ? row.sourceKey.value : null;
    final effectiveKey = (rawKey == null || rawKey.isEmpty) ? null : rawKey;
    // 归一化：空串 → null，防止多个空串挤占唯一索引。
    final normalized = effectiveKey == null
        ? row.copyWith(sourceKey: const Value(null))
        : row;
    return transaction(() async {
      await into(assetCostHistory)
          .insert(normalized, mode: InsertMode.insertOrIgnore);
      if (effectiveKey != null) {
        return (select(assetCostHistory)
              ..where((t) => t.sourceKey.equals(effectiveKey)))
            .getSingle();
      }
      return (select(assetCostHistory)
            ..where((t) => t.id.equals(row.id.value)))
          .getSingle();
    });
  }
}
