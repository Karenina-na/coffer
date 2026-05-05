import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/account_dao.dart';
import '../db/database.dart';
import '../repositories/drift_account_repository.dart';
import '../../domain/repositories/account_repository.dart';

/// 整库 Provider。应用启动时初始化一次。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 仅暴露 Schema 版本号。让设置页/关于页不必直接消费 Drift 实例（分层）。
final databaseSchemaVersionProvider = Provider<int>((ref) {
  return ref.watch(appDatabaseProvider).schemaVersion;
});

final accountDaoProvider = Provider<AccountDao>((ref) {
  return ref.watch(appDatabaseProvider).accountDao;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return DriftAccountRepository(ref.watch(accountDaoProvider));
});
