import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/assets.dart';

part 'asset_dao.g.dart';

@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Stream<List<AssetRow>> watchActive() {
    return (select(assets)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<AssetRow>> watchByAccount(String accountId) {
    return (select(assets)
          ..where(
            (t) => t.isDeleted.equals(false) & t.accountId.equals(accountId),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 订阅指定 id 的未软删除资产；软删除行视同不存在。
  Stream<AssetRow?> watchById(String id) {
    return (select(assets)
          ..where((t) => t.isDeleted.equals(false) & t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 按 id 查询资产（含软删除行）。用于 create 后的回读校验。
  Future<AssetRow?> findByIdAny(String id) {
    return (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 按 id 查询未软删除的资产。软删除行视同不存在。
  Future<AssetRow?> findById(String id) {
    return (select(assets)
          ..where((t) => t.isDeleted.equals(false) & t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertRow(AssetsCompanion row) async {
    await into(assets).insert(row);
  }

  Future<bool> replaceRow(AssetsCompanion row) {
    return update(assets).replace(row);
  }

  Future<int> updateStatus({
    required String id,
    required String status,
    required DateTime updatedAt,
  }) {
    return (update(assets)..where((t) => t.id.equals(id))).write(
      AssetsCompanion(status: Value(status), updatedAt: Value(updatedAt)),
    );
  }

  Future<int> softDelete(String id, DateTime updatedAt) {
    return (update(assets)..where((t) => t.id.equals(id))).write(
      AssetsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
