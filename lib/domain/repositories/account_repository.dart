import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account.dart';
import '../entities/account_enums.dart';

/// Account 仓储接口。数据层实现必须遵守此契约。
abstract interface class AccountRepository {
  /// 按创建时间倒序列出未软删除的账户。
  Stream<List<Account>> watchAll();

  /// 订阅指定 id 的未删除账户；不存在或已软删除时发出 `null`。
  Stream<Account?> watchById(String id);

  Future<Result<Account, AppError>> findById(String id);

  /// 新建账户；id、createdAt、updatedAt 由调用方提供（便于测试）。
  Future<Result<Account, AppError>> create(Account account);

  /// 全量更新已有账户。
  Future<Result<Account, AppError>> update(Account account);

  /// 仅更新状态字段。
  Future<Result<void, AppError>> updateStatus(String id, AccountStatus status);

  /// 软删除（is_deleted = 1）。
  Future<Result<void, AppError>> softDelete(String id);
}
