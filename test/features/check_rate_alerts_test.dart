import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_event_repository.dart';
import 'package:coffer/data/repositories/drift_exchange_rate_repository.dart';
import 'package:coffer/data/repositories/drift_watched_pair_repository.dart';
import 'package:coffer/domain/entities/exchange_rate.dart';
import 'package:coffer/domain/entities/exchange_rate_enums.dart';
import 'package:coffer/domain/events/event_bus.dart';
import 'package:coffer/domain/usecases/check_rate_alerts.dart';

void main() {
  late AppDatabase db;
  late DriftExchangeRateRepository rateRepo;
  late DriftWatchedPairRepository watchedRepo;
  late DriftEventRepository eventRepo;
  late CheckRateAlertsUseCase useCase;

  // 固定一个"现在"，保证 sourceKey 中的 yyyymmdd 稳定。
  final now = DateTime.utc(2025, 6, 15, 12);
  var seq = 0;

  setUp(() {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    rateRepo = DriftExchangeRateRepository(db.exchangeRateDao);
    watchedRepo = DriftWatchedPairRepository(db.watchedPairDao);
    eventRepo = DriftEventRepository(db.eventDao, now: () => now);
    useCase = CheckRateAlertsUseCase(
      watched: watchedRepo,
      rates: rateRepo,
      events: eventRepo,
      now: () => now,
      idGen: () => 'alert-${++seq}',
    );
  });

  tearDown(() => db.close());

  Future<void> seedPair({
    String base = 'USD',
    String quote = 'CNY',
    Decimal? high,
    Decimal? low,
    Decimal? pct,
  }) async {
    final r = await watchedRepo.add(baseCurrency: base, quoteCurrency: quote);
    final pair = r.valueOrNull!;
    await watchedRepo.updateThresholds(
      pairKey: pair.pairKey,
      thresholdHigh: high,
      thresholdLow: low,
      alertChangePct: pct,
    );
  }

  Future<void> seedRate({
    String pairKey = 'USD/CNY',
    required String rate,
    required DateTime asOf,
  }) async {
    final parts = pairKey.split('/');
    await rateRepo.upsert(
      ExchangeRate(
        id: 'r-${asOf.millisecondsSinceEpoch}-$pairKey',
        pairKey: pairKey,
        baseCurrency: parts[0],
        quoteCurrency: parts[1],
        rate: Decimal.parse(rate),
        asOfTime: asOf,
        updatedAt: now,
        source: 'test',
        snapshotType: SnapshotType.daily,
      ),
    );
  }

  test('无阈值的币对不触发事件', () async {
    await seedPair(high: null, low: null, pct: null);
    await seedRate(rate: '7.1', asOf: now);
    final r = await useCase();
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, isEmpty);
  });

  test('rate ≥ thresholdHigh 触发 high 预警', () async {
    await seedPair(high: Decimal.parse('7.0'));
    await seedRate(rate: '7.2', asOf: now);
    final r = await useCase();
    final list = r.valueOrNull!;
    expect(list, hasLength(1));
    expect(list.single.kind.code, 'high');
    final events = await eventRepo.watchRecent().first;
    expect(events.single.eventType, DomainEventTypes.rateAlert);
    expect(events.single.sourceKey, contains(':high'));
  });

  test('rate ≤ thresholdLow 触发 low 预警', () async {
    await seedPair(low: Decimal.parse('6.9'));
    await seedRate(rate: '6.8', asOf: now);
    final r = await useCase();
    final list = r.valueOrNull!;
    expect(list, hasLength(1));
    expect(list.single.kind.code, 'low');
  });

  test('最新汇率 <= 0 时跳过预警', () async {
    await seedPair(low: Decimal.parse('6.9'), pct: Decimal.parse('1.0'));
    await seedRate(rate: '7.0', asOf: now.subtract(const Duration(days: 1)));
    await seedRate(rate: '0', asOf: now);
    final r = await useCase();
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, isEmpty);
  });

  test('前序汇率 <= 0 时跳过波动预警', () async {
    await seedPair(pct: Decimal.parse('1.0'));
    await seedRate(rate: '-1', asOf: now.subtract(const Duration(days: 1)));
    await seedRate(rate: '7.1', asOf: now);
    final r = await useCase();
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, isEmpty);
  });

  test('波动 ≥ alertChangePct 触发 change 预警', () async {
    await seedPair(pct: Decimal.parse('1.0'));
    // 昨日 7.00，今日 7.10 → +1.43% > 1.0%
    await seedRate(rate: '7.00', asOf: now.subtract(const Duration(days: 1)));
    await seedRate(rate: '7.10', asOf: now);
    final r = await useCase();
    final list = r.valueOrNull!;
    expect(list, hasLength(1));
    expect(list.single.kind.code, 'change');
    expect(list.single.changePct!.abs(), greaterThan(Decimal.parse('1.0')));
  });

  test('波动 < alertChangePct 不触发', () async {
    await seedPair(pct: Decimal.parse('5.0'));
    await seedRate(rate: '7.00', asOf: now.subtract(const Duration(days: 1)));
    await seedRate(rate: '7.05', asOf: now);
    final r = await useCase();
    expect(r.valueOrNull, isEmpty);
  });

  test('同一天重复调用不会重复写入 RATE_ALERT（幂等）', () async {
    await seedPair(high: Decimal.parse('7.0'));
    await seedRate(rate: '7.2', asOf: now);

    await useCase();
    await useCase();
    final events = await eventRepo.watchRecent().first;
    final alerts = events
        .where((e) => e.eventType == DomainEventTypes.rateAlert)
        .toList();
    expect(alerts, hasLength(1));
  });

  test('同时越 high 与 change 触发两条独立事件', () async {
    await seedPair(high: Decimal.parse('7.0'), pct: Decimal.parse('1.0'));
    await seedRate(rate: '7.00', asOf: now.subtract(const Duration(days: 1)));
    await seedRate(rate: '7.20', asOf: now);
    final r = await useCase();
    final kinds = r.valueOrNull!.map((e) => e.kind.code).toSet();
    expect(kinds, containsAll(<String>['high', 'change']));
  });
}
