import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/accounts.dart';

part 'account_dao.g.dart';

/// Account 表的 Drift DAO。仅处理表级 CRUD，不包含领域语义。
@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  /// 订阅未软删除的账户，按创建时间倒序。
  Stream<List<AccountRow>> watchActive() {
    return (select(accounts)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 订阅指定 id 的未软删除账户；软删除行视同不存在，避免调用方
  /// 误将已删除账户当作有效数据读写。
  Stream<AccountRow?> watchById(String id) {
    return (select(accounts)
          ..where((t) => t.isDeleted.equals(false) & t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 按 id 查询未软删除的账户。软删除行视同不存在，避免调用方
  /// 误将已删除账户当作有效数据读写。
  Future<AccountRow?> findById(String id) {
    return (select(accounts)
          ..where((t) => t.isDeleted.equals(false) & t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertRow(AccountsCompanion row) async {
    await into(accounts).insert(row);
  }

  Future<bool> replaceRow(AccountsCompanion row) {
    return update(accounts).replace(row);
  }

  Future<int> updateStatus({
    required String id,
    required String status,
    required DateTime updatedAt,
  }) {
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(status: Value(status), updatedAt: Value(updatedAt)),
    );
  }

  Future<int> softDelete(String id, DateTime updatedAt) {
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
