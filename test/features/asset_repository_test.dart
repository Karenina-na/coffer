import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/create_asset.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftAssetRepository assetRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = DriftAccountRepository(db.accountDao);
    assetRepo = DriftAssetRepository(db.assetDao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAccount(String id) async {
    final uc = CreateAccountUseCase(
      accountRepo,
      idGenerator: () => id,
      now: DateTime.now,
    );
    await uc(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );
  }

  test('create 计算 market_value 并持久化 Decimal', () async {
    await seedAccount('acc-1');

    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-1',
      now: () => DateTime.utc(2026, 4, 21),
    );
    final r = await uc(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.parse('100'),
      currency: 'USD',
      assetCode: 'AAPL',
      costPrice: Decimal.parse('180.5'),
      currentPrice: Decimal.parse('200.25'),
    );
    expect(r.isOk, isTrue);

    final found = (await assetRepo.findById('ast-1')).valueOrNull!;
    expect(found.quantity, Decimal.parse('100'));
    expect(found.costPrice, Decimal.parse('180.5'));
    expect(found.currentPrice, Decimal.parse('200.25'));
    expect(found.marketValue, Decimal.parse('20025.00'));
    expect(
      found.valuationTime!.isAtSameMomentAs(DateTime.utc(2026, 4, 21)),
      isTrue,
    );
  });

  test('create 不提供 currentPrice 时 marketValue 为 null', () async {
    await seedAccount('acc-2');
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-2',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'acc-2',
      assetType: AssetType.crypto,
      quantity: Decimal.parse('1.5'),
      currency: 'BTC',
    );
    expect(r.isOk, isTrue);
    final a = r.valueOrNull!;
    expect(a.marketValue, isNull);
    expect(a.valuationTime, isNull);
  });

  test('account 不存在时返回 NotFoundError', () async {
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-x',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'missing',
      assetType: AssetType.fund,
      quantity: Decimal.parse('10'),
      currency: 'CNY',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('quantity < 0 返回 ValidationError', () async {
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'x',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'whatever',
      assetType: AssetType.fund,
      quantity: Decimal.parse('-1'),
      currency: 'CNY',
    );
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('watchByAccount 只返回本账户资产', () async {
    await seedAccount('acc-a');
    await seedAccount('acc-b');
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: _incrementingId(),
      now: DateTime.now,
    );
    await uc(
      accountId: 'acc-a',
      assetType: AssetType.stock,
      quantity: Decimal.one,
      currency: 'USD',
    );
    await uc(
      accountId: 'acc-b',
      assetType: AssetType.fund,
      quantity: Decimal.one,
      currency: 'CNY',
    );

    final list = await assetRepo.watchByAccount('acc-a').first;
    expect(list, hasLength(1));
    expect(list.first.currency, 'USD');
  });

  test('watchById 随软删除发出 null', () async {
    await seedAccount('acc-watch');
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-watch',
      now: DateTime.now,
    );
    await uc(
      accountId: 'acc-watch',
      assetType: AssetType.stock,
      quantity: Decimal.one,
      currency: 'USD',
    );

    expect((await assetRepo.watchById('ast-watch').first)?.id, 'ast-watch');

    await assetRepo.softDelete('ast-watch');
    expect(await assetRepo.watchById('ast-watch').first, isNull);
  });

  test('create 返回实体与 findById 结果一致（Bug 2 回读）', () async {
    await seedAccount('acc-reread');
    final uc = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-reread',
      now: () => DateTime.utc(2026, 4, 26),
    );
    final r = await uc(
      accountId: 'acc-reread',
      assetType: AssetType.stock,
      quantity: Decimal.parse('50'),
      currency: 'USD',
      currentPrice: Decimal.parse('100'),
    );
    expect(r.isOk, isTrue);
    final fromCreate = r.valueOrNull!;

    final fromDb = (await assetRepo.findById('ast-reread')).valueOrNull!;

    // The entity returned by create must match what findById returns.
    expect(fromCreate.id, fromDb.id);
    expect(fromCreate.quantity, fromDb.quantity);
    expect(fromCreate.currentPrice, fromDb.currentPrice);
    expect(fromCreate.marketValue, fromDb.marketValue);
    expect(fromCreate.createdAt, fromDb.createdAt);
    expect(fromCreate.updatedAt, fromDb.updatedAt);
  });
}

String Function() _incrementingId() {
  var i = 0;
  return () => 'ast-${++i}';
}
