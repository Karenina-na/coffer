import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_account_repository.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/usecases/create_account.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftAccountRepository(db.accountDao);
  });

  tearDown(() async {
    await db.close();
  });

  test('create + watchAll 返回新账户', () async {
    final usecase = CreateAccountUseCase(
      repo,
      idGenerator: () => 'acc-1',
      now: () => DateTime.utc(2026, 4, 21),
    );

    final r = await usecase(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: '招商银行',
      accountNo: '6225****0001',
    );
    expect(r.isOk, isTrue);

    final list = await repo.watchAll().first;
    expect(list, hasLength(1));
    expect(list.first.id, 'acc-1');
    expect(list.first.accountType, AccountType.bank);
    expect(list.first.institutionName, '招商银行');
    expect(list.first.status, AccountStatus.active);
  });

  test('updateStatus 改变状态并返回 Ok', () async {
    final uc = CreateAccountUseCase(
      repo,
      idGenerator: () => 'acc-2',
      now: DateTime.now,
    );
    await uc(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );

    final r = await repo.updateStatus('acc-2', AccountStatus.dormant);
    expect(r.isOk, isTrue);

    final found = (await repo.findById('acc-2')).valueOrNull!;
    expect(found.status, AccountStatus.dormant);
  });

  test('softDelete 后 watchAll 不再返回该账户', () async {
    final uc = CreateAccountUseCase(
      repo,
      idGenerator: () => 'acc-3',
      now: DateTime.now,
    );
    await uc(
      accountType: AccountType.cryptoWallet,
      sovereigntyRegion: 'SG',
      institutionName: 'Ledger',
    );

    await repo.softDelete('acc-3');
    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });

  test('watchById 随软删除发出 null', () async {
    final uc = CreateAccountUseCase(
      repo,
      idGenerator: () => 'acc-watch',
      now: DateTime.now,
    );
    await uc(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: '招商银行',
    );

    expect((await repo.watchById('acc-watch').first)?.id, 'acc-watch');

    await repo.softDelete('acc-watch');
    expect(await repo.watchById('acc-watch').first, isNull);
  });

  test('ValidationError: institutionName 为空', () async {
    final uc = CreateAccountUseCase(
      repo,
      idGenerator: () => 'x',
      now: DateTime.now,
    );
    final r = await uc(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: '   ',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('findById: NotFoundError', () async {
    final r = await repo.findById('missing');
    expect(r.errorOrNull, isA<NotFoundError>());
  });
}
