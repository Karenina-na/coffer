import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/core/result.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_exchange_rate_repository.dart';
import 'package:coffer/data/repositories/drift_watched_pair_repository.dart';
import 'package:coffer/domain/entities/exchange_rate.dart';
import 'package:coffer/domain/entities/exchange_rate_enums.dart';
import 'package:coffer/domain/providers/fx_rate_provider.dart';
import 'package:coffer/domain/usecases/refresh_watched_rates.dart';
import 'package:coffer/domain/utils/pair_key.dart';
import 'package:coffer/domain/valuation/asset_valuator.dart';

void main() {
  late AppDatabase db;
  late DriftExchangeRateRepository rateRepo;
  late DriftWatchedPairRepository watchedRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    rateRepo = DriftExchangeRateRepository(db.exchangeRateDao);
    watchedRepo = DriftWatchedPairRepository(db.watchedPairDao);
  });

  tearDown(() => db.close());

  RefreshWatchedRatesUseCase buildUseCase(FakeFxRateProvider provider) {
    return RefreshWatchedRatesUseCase(
      watchedRepo: watchedRepo,
      rateRepo: rateRepo,
      provider: provider,
    );
  }

  ExchangeRate makeRate({
    required String base,
    required String quote,
    required String rate,
    required DateTime asOfTime,
  }) {
    return ExchangeRate(
      id: 'r-${base}_${quote}_${asOfTime.microsecondsSinceEpoch}',
      pairKey: pairKeyOf(base, quote),
      baseCurrency: base,
      quoteCurrency: quote,
      rate: Decimal.parse(rate),
      asOfTime: asOfTime,
      updatedAt: asOfTime,
      source: 'test',
      snapshotType: SnapshotType.daily,
    );
  }

  group('RefreshWatchedRatesUseCase', () {
    test('无关注币对时返回空结果', () async {
      final provider = FakeFxRateProvider();
      final useCase = buildUseCase(provider);

      final r = await useCase.call();
      expect(r.isOk, isTrue);
      final result = r.valueOrNull!;
      expect(result.fetched, isEmpty);
      expect(result.failed, isEmpty);
    });

    test('增量模式：成功拉取并写入 rate', () async {
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      final provider = FakeFxRateProvider(
        latestDate: DateTime.utc(2025, 6, 15),
        latestRates: {'CNY': Decimal.parse('7.2')},
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.call(mode: SyncMode.incremental);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.fetched, ['USD/CNY']);
      expect(r.valueOrNull!.failed, isEmpty);

      final rates = await rateRepo.watchAll().first;
      expect(rates, hasLength(1));
      expect(rates.single.rate, Decimal.parse('7.2'));
    });

    test('增量模式：provider 失败时全部标记为 failed', () async {
      await watchedRepo.add(baseCurrency: 'EUR', quoteCurrency: 'USD');
      final provider = FakeFxRateProvider(latestError: '网络不可用');
      final useCase = buildUseCase(provider);

      final r = await useCase.call(mode: SyncMode.incremental);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.fetched, isEmpty);
      expect(r.valueOrNull!.failed, contains('EUR/USD'));
    });

    test('增量模式：provider 返回部分币种数据', () async {
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'JPY');
      final provider = FakeFxRateProvider(
        latestDate: DateTime.utc(2025, 6, 15),
        latestRates: {'CNY': Decimal.parse('7.2')}, // 缺 JPY
      );
      final useCase = buildUseCase(provider);

      final r = await useCase.call(mode: SyncMode.incremental);
      expect(r.valueOrNull!.fetched, ['USD/CNY']);
      expect(r.valueOrNull!.failed, contains('USD/JPY'));
    });

    test('全量模式：拉取时间序列并写入多条 rate', () async {
      final fixedNow = DateTime.utc(2025, 6, 15, 10, 30);
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      final provider = FakeFxRateProvider(
        seriesEntries: [
          MapEntry(DateTime.utc(2025, 6, 14), {'CNY': Decimal.parse('7.10')}),
          MapEntry(DateTime.utc(2025, 6, 15), {'CNY': Decimal.parse('7.20')}),
        ],
      );
      final useCase = RefreshWatchedRatesUseCase(
        watchedRepo: watchedRepo,
        rateRepo: rateRepo,
        provider: provider,
        now: () => fixedNow,
      );

      final r = await useCase.call(mode: SyncMode.full);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.fetched, ['USD/CNY']);
      expect(provider.lastFrom, DateTime.utc(2025, 6, 7));
      expect(provider.lastTo, DateTime.utc(2025, 6, 15));

      final rates = await rateRepo.watchAll().first;
      expect(rates, hasLength(2));
    });

    test('全量模式：time series 无数据时标记 failed', () async {
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      final provider = FakeFxRateProvider(seriesEntries: []);
      final useCase = buildUseCase(provider);

      final r = await useCase.call(mode: SyncMode.full);
      expect(r.valueOrNull!.fetched, isEmpty);
      expect(r.valueOrNull!.failed, contains('USD/CNY'));
    });

    test('全量模式：provider 失败', () async {
      await watchedRepo.add(baseCurrency: 'GBP', quoteCurrency: 'USD');
      final provider = FakeFxRateProvider(timeSeriesError: '远程服务忙');
      final useCase = buildUseCase(provider);

      final r = await useCase.call(mode: SyncMode.full);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.fetched, isEmpty);
      expect(r.valueOrNull!.failed, contains('GBP/USD'));
    });

    test('updatedAt 使用注入 clock 而非系统时钟（Bug 9）', () async {
      final fixedNow = DateTime.utc(2025, 6, 15, 10, 30);
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      final provider = FakeFxRateProvider(
        latestDate: fixedNow,
        latestRates: {'CNY': Decimal.parse('7.3')},
      );

      final useCase = RefreshWatchedRatesUseCase(
        watchedRepo: watchedRepo,
        rateRepo: rateRepo,
        provider: provider,
        now: () => fixedNow,
      );

      final r = await useCase.call(mode: SyncMode.incremental);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.fetched, ['USD/CNY']);

      final rates = await rateRepo.watchAll().first;
      expect(rates, hasLength(1));
      expect(
        rates.single.updatedAt.isAtSameMomentAs(fixedNow),
        isTrue,
        reason: 'updatedAt 应使用注入的 clock 而不是 DateTime.now()',
      );
    });

    test('删除关注币对时同时清除该币对已同步缓存', () async {
      final day1 = DateTime.utc(2025, 6, 14);
      final day2 = DateTime.utc(2025, 6, 15);
      await watchedRepo.add(baseCurrency: 'USD', quoteCurrency: 'CNY');
      await rateRepo.upsert(
        makeRate(base: 'USD', quote: 'CNY', rate: '7.1', asOfTime: day1),
      );
      await rateRepo.upsert(
        makeRate(base: 'USD', quote: 'CNY', rate: '7.2', asOfTime: day2),
      );

      final remove = await watchedRepo.remove('USD/CNY');
      expect(remove.isOk, isTrue);
      expect(await watchedRepo.listAll(), isEmpty);
      expect(
        await rateRepo.querySeriesForPair(
          pairKey: 'USD/CNY',
          since: DateTime.utc(2025, 6, 1),
        ),
        isEmpty,
      );

      final latest = await rateRepo.latestFor(baseCurrency: 'USD', quoteCurrency: 'CNY');
      expect(latest.isErr, isTrue);
      expect(latest.errorOrNull, isA<NotFoundError>());
    });
  });
}

class FakeFxRateProvider implements FxRateProvider {
  FakeFxRateProvider({
    DateTime? latestDate,
    Map<String, Decimal>? latestRates,
    List<MapEntry<DateTime, Map<String, Decimal>>>? seriesEntries,
    String? latestError,
    String? timeSeriesError,
  })  : _latestDate = latestDate,
        _latestRates = latestRates,
        _seriesEntries = seriesEntries,
        _latestError = latestError,
        _timeSeriesError = timeSeriesError;

  final DateTime? _latestDate;
  final Map<String, Decimal>? _latestRates;
  final List<MapEntry<DateTime, Map<String, Decimal>>>? _seriesEntries;
  final String? _latestError;
  final String? _timeSeriesError;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<Result<FxSnapshot, AppError>> fetchLatest({
    required String base,
    required List<String> symbols,
  }) async {
    if (_latestError != null) {
      return Err(UnknownError(_latestError));
    }
    final date = _latestDate;
    final rates = _latestRates;
    if (date == null || rates == null) {
      return Err(UnknownError('no data'));
    }
    return Ok(FxSnapshot(
      base: base,
      date: date,
      rates: rates,
      rawPayload: '{}',
    ));
  }

  @override
  Future<Result<FxTimeSeries, AppError>> fetchTimeSeries({
    required String base,
    required List<String> symbols,
    required DateTime from,
    required DateTime to,
  }) async {
    lastFrom = from;
    lastTo = to;
    if (_timeSeriesError != null) {
      return Err(UnknownError(_timeSeriesError));
    }
    final entries = _seriesEntries;
    if (entries == null) {
      return Err(UnknownError('no data'));
    }
    return Ok(FxTimeSeries(
      base: base,
      series: entries,
      rawPayload: '{}',
    ));
  }
}
