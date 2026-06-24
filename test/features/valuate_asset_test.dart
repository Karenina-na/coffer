import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_account_repository.dart';
import 'package:coffer/data/repositories/drift_asset_price_history_repository.dart';
import 'package:coffer/data/repositories/drift_asset_repository.dart';
import 'package:coffer/data/repositories/drift_exchange_rate_repository.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/entities/exchange_rate.dart';
import 'package:coffer/domain/entities/exchange_rate_enums.dart';
import 'package:coffer/domain/usecases/create_account.dart';
import 'package:coffer/domain/usecases/create_asset.dart';
import 'package:coffer/domain/usecases/valuate_asset.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftAssetRepository assets;
  late DriftAssetPriceHistoryRepository priceHistory;
  late DriftExchangeRateRepository rates;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    assets = DriftAssetRepository(db.assetDao);
    priceHistory = DriftAssetPriceHistoryRepository(
      db.assetPriceHistoryDao,
    );
    rates = DriftExchangeRateRepository(db.exchangeRateDao);

    await CreateAccountUseCase(
      accounts,
      idGenerator: () => 'acc-1',
      now: DateTime.now,
    )(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );
    await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'ast-1',
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.parse('10'),
      currency: 'USD',
      currentPrice: Decimal.parse('100'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  ValuateAssetUseCase buildUc({int startId = 1}) {
    var i = startId;
    return ValuateAssetUseCase(
      assets,
      priceHistory,
      rates,
      idGenerator: () => 'pp-${i++}',
      now: () => DateTime.utc(2026, 4, 21, 10),
    );
  }

  test('相同币种下更新价格重算 market_value 并写入价格历史', () async {
    final r = await buildUc()(
      assetId: 'ast-1',
      newPrice: Decimal.parse('125.5'),
    );
    expect(r.isOk, isTrue);
    final updated = r.valueOrNull!;
    expect(updated.currentPrice, Decimal.parse('125.5'));
    expect(updated.marketValue, Decimal.parse('1255.0'));

    // 价格历史表写入了一条
    final persisted = await priceHistory.watchByAsset('ast-1').first;
    expect(persisted, hasLength(1));
    expect(persisted.single.assetId, 'ast-1');
    expect(persisted.single.price, Decimal.parse('125.5'));
    expect(persisted.single.marketValue, Decimal.parse('1255.0'));
  });

  test('跨币种按 ExchangeRate 折算', () async {
    final now = DateTime.utc(2026, 4, 21);
    await rates.upsert(
      ExchangeRate(
        id: 'fx-1',
        pairKey: 'USD/HKD',
        baseCurrency: 'USD',
        quoteCurrency: 'HKD',
        rate: Decimal.parse('7.8'),
        asOfTime: now,
        updatedAt: now,
        source: 'manual',
        snapshotType: SnapshotType.daily,
      ),
    );

    await assets.softDelete('ast-1');
    await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'ast-hk',
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.parse('10'),
      currency: 'HKD',
    );

    final r = await buildUc()(
      assetId: 'ast-hk',
      newPrice: Decimal.parse('100'),
      priceCurrency: 'USD',
    );
    expect(r.isOk, isTrue);
    final a = r.valueOrNull!;
    expect(a.currentPrice, Decimal.parse('780.0'));
    expect(a.marketValue, Decimal.parse('7800.0'));
  });

  test('缺失汇率返回 NotFoundError，不写价格历史', () async {
    await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'ast-eur',
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.one,
      currency: 'EUR',
    );

    final r = await buildUc()(
      assetId: 'ast-eur',
      newPrice: Decimal.parse('1'),
      priceCurrency: 'JPY',
    );
    expect(r.isErr, isTrue);

    final persisted = await priceHistory.watchByAsset('ast-eur').first;
    expect(persisted, isEmpty);
  });

  test('价格 <= 0 被拦截，不写价格历史', () async {
    final r = await buildUc()(
      assetId: 'ast-1',
      newPrice: Decimal.zero,
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());

    final persisted = await priceHistory.watchByAsset('ast-1').first;
    expect(persisted, isEmpty);
  });

  test('汇率 <= 0 被拦截，不写价格历史', () async {
    final now = DateTime.utc(2026, 4, 21);
    await rates.upsert(
      ExchangeRate(
        id: 'fx-zero',
        pairKey: 'USD/HKD',
        baseCurrency: 'USD',
        quoteCurrency: 'HKD',
        rate: Decimal.zero,
        asOfTime: now,
        updatedAt: now,
        source: 'manual',
        snapshotType: SnapshotType.daily,
      ),
    );

    await assets.softDelete('ast-1');
    await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'ast-hk-zero',
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.parse('10'),
      currency: 'HKD',
    );

    final r = await buildUc()(
      assetId: 'ast-hk-zero',
      newPrice: Decimal.parse('100'),
      priceCurrency: 'USD',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());

    final persisted = await priceHistory.watchByAsset('ast-hk-zero').first;
    expect(persisted, isEmpty);
  });

  test('写入价格历史带 sourceKey（{assetId}:{yyyymmdd}:{source}）', () async {
    final r = await buildUc()(
      assetId: 'ast-1',
      newPrice: Decimal.parse('100'),
      source: 'yahoo',
    );
    expect(r.isOk, isTrue);

    final persisted = await priceHistory.watchByAsset('ast-1').first;
    expect(persisted, hasLength(1));
    final p = persisted.single;
    expect(p.sourceKey, 'ast-1:20260421:yahoo');
    expect(p.source, 'yahoo');
  });

  test('同日同源重复估值幂等，不写两条价格历史', () async {
    final uc = buildUc();
    final r1 = await uc(
      assetId: 'ast-1',
      newPrice: Decimal.parse('100'),
      source: 'eastmoney',
    );
    expect(r1.isOk, isTrue);
    final r2 = await uc(
      assetId: 'ast-1',
      newPrice: Decimal.parse('110'),
      source: 'eastmoney',
    );
    // 资产本身仍更新成功（价格变了），但历史不重写
    expect(r2.isOk, isTrue);
    expect(r2.valueOrNull!.currentPrice, Decimal.parse('110'));

    final persisted = await priceHistory.watchByAsset('ast-1').first;
    expect(persisted, hasLength(1));
  });

  test('不同 source 在同日各记一条价格历史', () async {
    final uc = buildUc();
    await uc(assetId: 'ast-1', newPrice: Decimal.parse('100'), source: 'yahoo');
    await uc(
      assetId: 'ast-1',
      newPrice: Decimal.parse('101'),
      source: 'eastmoney',
    );
    final persisted = await priceHistory.watchByAsset('ast-1').first;
    expect(persisted, hasLength(2));
    expect(
      persisted.map((e) => e.source).toSet(),
      {'yahoo', 'eastmoney'},
    );
  });
}
