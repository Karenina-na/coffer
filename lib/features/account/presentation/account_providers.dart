import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/providers/account_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/usecases/create_account.dart';

export '../../../data/providers/account_providers.dart'
    show
        appDatabaseProvider,
        databaseSchemaVersionProvider,
        accountDaoProvider,
        accountRepositoryProvider;

/// 账户列表流：Drift watch 自动随写操作刷新。
final accountListProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final accountByIdProvider = StreamProvider.family<Account?, String>((
  ref,
  accountId,
) {
  return ref.watch(accountRepositoryProvider).watchById(accountId);
});

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  const uuid = Uuid();
  return CreateAccountUseCase(
    ref.watch(accountRepositoryProvider),
    idGenerator: uuid.v4,
    now: DateTime.now,
  );
});
