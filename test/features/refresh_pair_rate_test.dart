import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/domain/providers/fx_rate_provider.dart';
import 'package:gwp/domain/usecases/refresh_pair_rate.dart';
import 'package:gwp/domain/valuation/asset_valuator.dart';

void main() {
  late AppDatabase db;
  late DriftExchangeRateRepository rateRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    rateRepo = DriftExchangeRateRepository(db.exchangeRateDao);
  });

  tearDown(() => db.close());

  test('window drives current pair history range and latest write', () async {
    final fixedNow = DateTime.utc(2025, 6, 15, 10, 30);
    final provider = _FakeFxRateProvider(
      latestDate: DateTime.utc(2025, 6, 15),
      latestRates: {'CNY': Decimal.parse('7.20')},
      seriesEntries: [
        MapEntry(DateTime.utc(2025, 6, 14), {'CNY': Decimal.parse('7.10')}),
        MapEntry(DateTime.utc(2025, 6, 15), {'CNY': Decimal.parse('7.20')}),
      ],
    );
    final useCase = RefreshPairRateUseCase(
      rates: rateRepo,
      provider: provider,
      now: () => fixedNow,
    );

    final r = await useCase.call(pairKey: 'USD/CNY', window: SyncWindow.year1);

    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.pairKey, 'USD/CNY');
    expect(r.valueOrNull!.historyCount, 2);
    expect(r.valueOrNull!.latestUpdated, isTrue);
    expect(provider.lastFrom, DateTime.utc(2024, 6, 15));
    expect(provider.lastTo, DateTime.utc(2025, 6, 15));

    final saved = await rateRepo.watchAll().first;
    expect(saved, hasLength(2));
    expect(saved.every((e) => e.pairKey == 'USD/CNY'), isTrue);
  });

  test('invalid pairKey returns validation error', () async {
    final useCase = RefreshPairRateUseCase(
      rates: rateRepo,
      provider: _FakeFxRateProvider(),
    );

    final r = await useCase.call(pairKey: 'broken', window: SyncWindow.days8);

    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('provider error bubbles up', () async {
    final useCase = RefreshPairRateUseCase(
      rates: rateRepo,
      provider: _FakeFxRateProvider(timeSeriesError: '远程服务忙'),
    );

    final r = await useCase.call(pairKey: 'USD/CNY', window: SyncWindow.days8);

    expect(r.isErr, isTrue);
    expect(r.errorOrNull?.message, contains('远程服务忙'));
  });
}

class _FakeFxRateProvider implements FxRateProvider {
  _FakeFxRateProvider({
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
    if (_latestError != null) return Err(UnknownError(_latestError));
    final date = _latestDate;
    final rates = _latestRates;
    if (date == null || rates == null) return Err(UnknownError('no data'));
    return Ok(FxSnapshot(base: base, date: date, rates: rates, rawPayload: '{}'));
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
    if (_timeSeriesError != null) return Err(UnknownError(_timeSeriesError));
    final entries = _seriesEntries;
    if (entries == null) return Err(UnknownError('no data'));
    return Ok(FxTimeSeries(base: base, series: entries, rawPayload: '{}'));
  }
}

