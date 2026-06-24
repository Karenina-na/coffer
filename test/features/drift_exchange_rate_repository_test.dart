import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_exchange_rate_repository.dart';
import 'package:coffer/domain/entities/exchange_rate.dart';
import 'package:coffer/domain/entities/exchange_rate_enums.dart';
import 'package:coffer/domain/utils/pair_key.dart';

void main() {
  late AppDatabase db;
  late DriftExchangeRateRepository repo;
  var seq = 0;

  setUp(() {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftExchangeRateRepository(db.exchangeRateDao);
  });

  tearDown(() => db.close());

  ExchangeRate makeRate({
    required String base,
    required String quote,
    required String rate,
    required DateTime asOfTime,
  }) {
    return ExchangeRate(
      id: 'r-${++seq}',
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

  test('upsert and latestFor returns most recent rate', () async {
    final t1 = DateTime.utc(2025, 6, 14);
    final t2 = DateTime.utc(2025, 6, 15);
    await repo.upsert(makeRate(base: 'USD', quote: 'CNY', rate: '7.1', asOfTime: t1));
    await repo.upsert(makeRate(base: 'USD', quote: 'CNY', rate: '7.2', asOfTime: t2));

    final r = await repo.latestFor(baseCurrency: 'USD', quoteCurrency: 'CNY');
    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.rate, Decimal.parse('7.2'));
  });

  test('latestFor returns NotFoundError when no data', () async {
    final r = await repo.latestFor(baseCurrency: 'EUR', quoteCurrency: 'JPY');
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('querySeriesForPair returns data since given time', () async {
    final base = DateTime.utc(2025, 6, 10);
    for (var i = 0; i < 5; i++) {
      await repo.upsert(makeRate(
        base: 'USD',
        quote: 'CNY',
        rate: '7.${i + 1}',
        asOfTime: base.add(Duration(days: i)),
      ));
    }

    final since = DateTime.utc(2025, 6, 12);
    final list = await repo.querySeriesForPair(
      pairKey: pairKeyOf('USD', 'CNY'),
      since: since,
    );
    // days 12, 13, 14 => 3 entries
    expect(list.length, 3);
    for (final r in list) {
      expect(r.asOfTime.isBefore(since), isFalse);
    }
  });

  test('queryForDate returns rate on that UTC day', () async {
    final day = DateTime.utc(2025, 6, 15, 14, 30);
    await repo.upsert(makeRate(base: 'USD', quote: 'EUR', rate: '0.92', asOfTime: day));
    // Different day
    await repo.upsert(makeRate(
      base: 'USD',
      quote: 'EUR',
      rate: '0.91',
      asOfTime: DateTime.utc(2025, 6, 14, 10),
    ));

    final found = await repo.queryForDate(
      baseCurrency: 'USD',
      quoteCurrency: 'EUR',
      date: DateTime.utc(2025, 6, 15),
    );
    expect(found, isNotNull);
    expect(found!.rate, Decimal.parse('0.92'));
  });

  test('queryForDate returns null when no rate on that day', () async {
    final found = await repo.queryForDate(
      baseCurrency: 'USD',
      quoteCurrency: 'JPY',
      date: DateTime.utc(2025, 6, 15),
    );
    expect(found, isNull);
  });

  test('watchSeriesForPair emits live updates', () async {
    final t1 = DateTime.utc(2025, 6, 14);
    final t2 = DateTime.utc(2025, 6, 15);

    final stream = repo.watchSeriesForPair(
      pairKey: pairKeyOf('USD', 'CNY'),
      since: t1,
    );
    final events = <int>[];
    final sub = stream.map((l) => l.length).listen(events.add);

    await repo.upsert(makeRate(base: 'USD', quote: 'CNY', rate: '7.1', asOfTime: t1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.upsert(makeRate(base: 'USD', quote: 'CNY', rate: '7.2', asOfTime: t2));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.last, 2);
    await sub.cancel();
  });

  test('getRate returns Decimal.one for same currency', () async {
    final r = await repo.getRate(baseCurrency: 'USD', quoteCurrency: 'USD');
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, Decimal.one);
  });
}
