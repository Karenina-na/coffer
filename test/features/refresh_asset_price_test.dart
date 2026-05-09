import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/data/repositories/drift_event_repository.dart';
import 'package:gwp/data/repositories/drift_asset_price_history_repository.dart';
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/exchange_rate.dart';
import 'package:gwp/domain/entities/exchange_rate_enums.dart';
import 'package:gwp/domain/events/event_bus.dart';
import 'package:gwp/domain/repositories/exchange_rate_repository.dart';
import 'package:gwp/domain/usecases/refresh_asset_price.dart';
import 'package:gwp/domain/usecases/valuate_asset.dart';
import 'package:gwp/domain/utils/pair_key.dart';
import 'package:gwp/domain/valuation/asset_valuator.dart';
import 'package:gwp/domain/valuation/strategies/market_quote_valuator.dart';

import 'asset_valuator_test_helpers.dart';

void main() {
  late AppDatabase db;
  late DriftAssetRepository assetRepo;
  late DriftEventRepository eventRepo;
  late DriftAssetPriceHistoryRepository historyRepo;
  late DomainEventBus bus;

  final now = DateTime.utc(2025, 6, 15, 12);
  var seq = 0;

  setUp(() async {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    assetRepo = DriftAssetRepository(db.assetDao);
    eventRepo = DriftEventRepository(db.eventDao, now: () => now);
    historyRepo = DriftAssetPriceHistoryRepository(db.assetPriceHistoryDao);
    bus = DomainEventBus();
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-1', 'BROKER', 'US', 'IBKR', 'ACTIVE', 1749988800, 1749988800, 0)",
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  Future<Asset> seedAsset({
    String id = 'ast-1',
    String currency = 'USD',
    String? assetCode,
  }) async {
    final asset = Asset(
      id: id,
      accountId: 'acc-1',
      assetType: AssetType.stock,
      assetCode: assetCode,
      quantity: Decimal.fromInt(10),
      currency: currency,
      status: AssetStatus.holding,
      createdAt: now,
      updatedAt: now,
    );
    final r = await assetRepo.create(asset);
    expect(r.isOk, isTrue, reason: 'seed $id failed: ${r.errorOrNull?.message}');
    return r.valueOrNull!;
  }

  PriceProvider fixedRate(Decimal rate) => _FixedRateProvider(rate);

  RefreshAssetPriceUseCase buildUseCase(FakeAssetPriceProvider provider) {
    final valuator = SimpleFakeValuator(provider);
    final valuate = ValuateAssetUseCase(
      assetRepo,
      historyRepo,
      fixedRate(Decimal.one),
      idGenerator: () => 'evt-${++seq}',
      now: () => now,
    );
    return RefreshAssetPriceUseCase(
      assets: assetRepo,
      events: eventRepo,
      priceHistory: historyRepo,
      bus: bus,
      fxRates: fixedRate(Decimal.one),
      valuator: valuator,
      valuate: valuate,
      idGenerator: () => 'id-${++seq}',
      now: () => now,
    );
  }

  RefreshAssetPriceUseCase buildCachedUseCase(FakeAssetPriceProvider provider) {
    final valuator = MarketQuoteValuator(
      source: provider,
      clock: () => now,
      latestTtl: const Duration(minutes: 5),
      historyTtl: const Duration(hours: 6),
    );
    final valuate = ValuateAssetUseCase(
      assetRepo,
      historyRepo,
      fixedRate(Decimal.one),
      idGenerator: () => 'evt-${++seq}',
      now: () => now,
    );
    return RefreshAssetPriceUseCase(
      assets: assetRepo,
      events: eventRepo,
      priceHistory: historyRepo,
      bus: bus,
      fxRates: fixedRate(Decimal.one),
      valuator: valuator,
      valuate: valuate,
      idGenerator: () => 'id-${++seq}',
      now: () => now,
    );
  }

  group('refreshLatest', () {
    test('成功的估值应更新资产当前价', () async {
      await seedAsset(id: 'ast-1', assetCode: 'AAPL');
      final provider = FakeAssetPriceProvider(
        latest: AssetQuote(
          symbol: 'AAPL',
          price: Decimal.parse('150'),
          currency: 'USD',
          asOfTime: now,
          source: 'test',
        ),
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshLatest('ast-1');
      expect(r.isOk, isTrue);

      final updated = await assetRepo.findById('ast-1');
      expect(updated.valueOrNull?.currentPrice, Decimal.parse('150'));
      expect(updated.valueOrNull?.marketValue, Decimal.parse('1500'));
      expect(updated.valueOrNull?.valuationTime, isNotNull);
    });

    test('资产不存在返回错误', () async {
      final provider = FakeAssetPriceProvider();
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshLatest('nonexistent');
      expect(r.isErr, isTrue);
    });

    test('估值器失败时写入失败事件', () async {
      await seedAsset(id: 'ast-1', assetCode: 'AAPL');
      final provider = FakeAssetPriceProvider(); // default: no data error
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshLatest('ast-1');
      expect(r.isErr, isTrue);

      final events = await eventRepo.watchRecent().first;
      final failed = events.where(
        (e) => e.eventType == DomainEventTypes.assetValuationFailed,
      ).toList();
      expect(failed, hasLength(1));
    });
  });

  group('refreshAll', () {
    test('空 targets 返回空结果', () async {
      final provider = FakeAssetPriceProvider();
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshAll(assetIds: []);
      expect(r.valueOrNull?.success, isEmpty);
      expect(r.valueOrNull?.failed, isEmpty);
    });

    test('按 assetIds 只刷新指定资产', () async {
      await seedAsset(id: 'ast-1', assetCode: 'A');
      await seedAsset(id: 'ast-2', assetCode: 'B');
      final provider = FakeAssetPriceProvider(
        latest: AssetQuote(
          symbol: 'A',
          price: Decimal.parse('100'),
          currency: 'USD',
          asOfTime: now,
          source: 'test',
        ),
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshAll(assetIds: ['ast-1']);
      expect(r.valueOrNull?.success, ['ast-1']);
    });

    test('无效 assetIds 被静默忽略', () async {
      await seedAsset(id: 'ast-1', assetCode: 'A');
      final provider = FakeAssetPriceProvider(
        latest: AssetQuote(
          symbol: 'A',
          price: Decimal.parse('100'),
          currency: 'USD',
          asOfTime: now,
          source: 'test',
        ),
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshAll(assetIds: ['ast-1', 'ghost']);
      expect(r.valueOrNull?.success, ['ast-1']);
      expect(r.valueOrNull?.failed, containsPair('ghost', contains('not found')));
    });

    test('重复 refreshAll 增量模式在 TTL 内复用 latest 缓存', () async {
      await seedAsset(id: 'ast-1', assetCode: 'AAPL');
      final provider = FakeAssetPriceProvider(
        latest: AssetQuote(
          symbol: 'AAPL',
          price: Decimal.parse('100'),
          currency: 'USD',
          asOfTime: now,
          source: 'test',
        ),
      );
      final useCase = buildCachedUseCase(provider);

      final r1 = await useCase.refreshAll(mode: SyncMode.incremental);
      final r2 = await useCase.refreshAll(mode: SyncMode.incremental);

      expect(r1.isOk, isTrue);
      expect(r2.isOk, isTrue);
      expect(provider.latestCalls, 1,
          reason: 'TTL 窗口内二次批量刷新不应再次打远端');
    });

    test('window 会驱动批量历史刷新范围', () async {
      await seedAsset(id: 'ast-1', assetCode: 'AAPL');
      final provider = FakeAssetPriceProvider(
        latest: AssetQuote(
          symbol: 'AAPL',
          price: Decimal.parse('100'),
          currency: 'USD',
          asOfTime: now,
          source: 'test',
        ),
        series: AssetPriceSeries(
          symbol: 'AAPL',
          currency: 'USD',
          source: 'test',
          points: [
            AssetPricePoint(
              t: now.subtract(const Duration(days: 1)),
              price: Decimal.parse('98'),
              currency: 'USD',
            ),
          ],
        ),
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshAll(window: SyncWindow.year1);
      expect(r.isOk, isTrue);
      expect(provider.lastFrom, DateTime.utc(2024, 6, 15));
      expect(provider.lastTo, DateTime.utc(2025, 6, 15));
      expect(provider.seriesCalls, 1);
      expect(provider.latestCalls, 1);
    });
  });

  group('refreshHistory', () {
    test('from > to 返回 ValidationError', () async {
      await seedAsset(id: 'ast-1');
      final provider = FakeAssetPriceProvider();
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshHistory(
        assetId: 'ast-1',
        from: now,
        to: now.subtract(const Duration(days: 1)),
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('资产不存在返回错误', () async {
      final provider = FakeAssetPriceProvider();
      final useCase = buildUseCase(provider);

      final r = await useCase.refreshHistory(
        assetId: 'nonexistent',
        from: now.subtract(const Duration(days: 30)),
        to: now,
      );
      expect(r.isErr, isTrue);
    });

    test('重复 refreshHistory 在 TTL 内复用 history 缓存', () async {
      await seedAsset(id: 'ast-1', assetCode: 'AAPL');
      final provider = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: 'AAPL',
          currency: 'USD',
          source: 'test',
          points: [
            AssetPricePoint(
              t: now.subtract(const Duration(days: 1)),
              price: Decimal.parse('100'),
              currency: 'USD',
            ),
          ],
        ),
      );
      final useCase = buildCachedUseCase(provider);

      final from = now.subtract(const Duration(days: 1));
      final to = now;
      final r1 = await useCase.refreshHistory(assetId: 'ast-1', from: from, to: to);
      final r2 = await useCase.refreshHistory(assetId: 'ast-1', from: from, to: to);

      expect(r1.isOk, isTrue);
      expect(r2.isOk, isTrue);
      expect(provider.seriesCalls, 1,
          reason: 'TTL 窗口内重复拉历史不应再次打远端');
    });
  });

  group('refreshHistory FX（Bug 8）', () {
    // Build a useCase with the real DriftExchangeRateRepository injected.
    RefreshAssetPriceUseCase buildWithFxRepo(
      FakeAssetPriceProvider provider,
      DriftExchangeRateRepository fxRepo,
    ) {
      final valuator = SimpleFakeValuator(provider);
      final valuate = ValuateAssetUseCase(
        assetRepo,
        historyRepo,
        fixedRate(Decimal.one),
        idGenerator: () => 'evt-${++seq}',
        now: () => now,
      );
      return RefreshAssetPriceUseCase(
        assets: assetRepo,
        events: eventRepo,
        priceHistory: historyRepo,
        bus: bus,
        fxRates: fixedRate(Decimal.parse('7.0')), // spot rate fallback
        valuator: valuator,
        valuate: valuate,
        idGenerator: () => 'id-${++seq}',
        now: () => now,
        fxRateRepository: fxRepo,
      );
    }

    test('历史 FX 按日换算：每个点使用当日汇率（Bug 8）', () async {
      final fxRepo = DriftExchangeRateRepository(db.exchangeRateDao);
      // Insert per-day FX rates for two different days
      final day1 = DateTime.utc(2025, 6, 13);
      final day2 = DateTime.utc(2025, 6, 14);
      await fxRepo.upsert(ExchangeRate(
        id: 'r1',
        pairKey: pairKeyOf('USD', 'CNY'),
        baseCurrency: 'USD',
        quoteCurrency: 'CNY',
        rate: Decimal.parse('7.1'),
        asOfTime: day1.add(const Duration(hours: 12)),
        updatedAt: day1,
        source: 'test',
        snapshotType: SnapshotType.daily,
      ));
      await fxRepo.upsert(ExchangeRate(
        id: 'r2',
        pairKey: pairKeyOf('USD', 'CNY'),
        baseCurrency: 'USD',
        quoteCurrency: 'CNY',
        rate: Decimal.parse('7.2'),
        asOfTime: day2.add(const Duration(hours: 12)),
        updatedAt: day2,
        source: 'test',
        snapshotType: SnapshotType.daily,
      ));

      // Asset is priced in CNY, quotes come in USD
      final asset = await seedAsset(id: 'ast-fx', currency: 'CNY');
      final provider = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: asset.assetCode ?? '',
          currency: 'USD',
          source: 'test',
          points: [
            AssetPricePoint(t: day1, price: Decimal.parse('100'), currency: 'USD'),
            AssetPricePoint(t: day2, price: Decimal.parse('100'), currency: 'USD'),
          ],
        ),
      );
      final useCase = buildWithFxRepo(provider, fxRepo);

      final r = await useCase.refreshHistory(
        assetId: 'ast-fx',
        from: day1,
        to: day2,
      );
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 2);

      // Verify two history points were written with different prices
      final history = await historyRepo.watchByAsset('ast-fx').first;
      expect(history.length, 2);
      final prices = history.map((p) => p.price).toSet();
      // day1: 100 * 7.1 = 710, day2: 100 * 7.2 = 720 — they must differ
      expect(prices.length, 2, reason: '每天应使用不同汇率换算出不同价格');
    });

    test('历史 FX 使用 asOfTime，而不是 updatedAt 建索引', () async {
      final fxRepo = DriftExchangeRateRepository(db.exchangeRateDao);
      final day1 = DateTime.utc(2025, 6, 13);
      final day2 = DateTime.utc(2025, 6, 14);
      await fxRepo.upsert(ExchangeRate(
        id: 'r1-late',
        pairKey: pairKeyOf('USD', 'CNY'),
        baseCurrency: 'USD',
        quoteCurrency: 'CNY',
        rate: Decimal.parse('7.1'),
        asOfTime: day1.add(const Duration(hours: 12)),
        updatedAt: day2.add(const Duration(hours: 6)),
        source: 'test',
        snapshotType: SnapshotType.daily,
      ));

      final asset = await seedAsset(id: 'ast-fx-asof', currency: 'CNY');
      final provider = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: asset.assetCode ?? '',
          currency: 'USD',
          source: 'test',
          points: [
            AssetPricePoint(t: day1, price: Decimal.parse('100'), currency: 'USD'),
          ],
        ),
      );
      final useCase = buildWithFxRepo(provider, fxRepo);

      final r = await useCase.refreshHistory(
        assetId: 'ast-fx-asof',
        from: day1,
        to: day1,
      );
      expect(r.isOk, isTrue);

      final history = await historyRepo.watchByAsset('ast-fx-asof').first;
      expect(history.single.price, Decimal.parse('710'));
    });

    test('同币种资产不做 FX 换算', () async {
      final fxRepo = DriftExchangeRateRepository(db.exchangeRateDao);
      final day = DateTime.utc(2025, 6, 14);

      final asset = await seedAsset(id: 'ast-usd', currency: 'USD');
      final provider = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: asset.assetCode ?? '',
          currency: 'USD', // same as asset currency
          source: 'test',
          points: [AssetPricePoint(t: day, price: Decimal.parse('150'), currency: 'USD')],
        ),
      );
      final useCase = buildWithFxRepo(provider, fxRepo);

      final r = await useCase.refreshHistory(
        assetId: 'ast-usd',
        from: day,
        to: day.add(const Duration(hours: 1)),
      );
      expect(r.isOk, isTrue);

      final history = await historyRepo.watchByAsset('ast-usd').first;
      expect(history.length, 1);
      // Price should not be multiplied by any FX rate
      expect(history.single.price, Decimal.parse('150'));
    });

    test('FX 查询失败时使用 spot rate 作为降级', () async {
      final fxRepo = DriftExchangeRateRepository(db.exchangeRateDao);
      // No FX rates in DB — queryForDate will return null → fall back to spot
      final day = DateTime.utc(2025, 6, 14);

      final asset = await seedAsset(id: 'ast-fallback', currency: 'CNY');
      final provider = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: asset.assetCode ?? '',
          currency: 'USD',
          source: 'test',
          points: [AssetPricePoint(t: day, price: Decimal.parse('100'), currency: 'USD')],
        ),
      );
      final useCase = buildWithFxRepo(provider, fxRepo);

      // Should succeed using spot rate fallback (7.0)
      final r = await useCase.refreshHistory(
        assetId: 'ast-fallback',
        from: day,
        to: day.add(const Duration(hours: 1)),
      );
      expect(r.isOk, isTrue);

      final history = await historyRepo.watchByAsset('ast-fallback').first;
      expect(history.length, 1);
      // 100 * 7.0 (spot fallback) = 700
      expect(history.single.price, Decimal.parse('700'));
    });
  });
}

class SimpleFakeValuator implements AssetValuator {
  SimpleFakeValuator(this._provider);

  final FakeAssetPriceProvider _provider;

  @override
  bool supports(Asset asset) => true;

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) =>
      _provider.fetchLatest(asset.assetCode ?? '');

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) =>
      _provider.fetchTimeSeries(symbol: asset.assetCode ?? '', from: from, to: to);
}

class _FixedRateProvider implements PriceProvider {
  const _FixedRateProvider(this._rate);

  final Decimal _rate;

  @override
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  }) async =>
      Ok(_rate);
}
