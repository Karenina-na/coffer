import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/asset/composite_asset_price_provider.dart';
import 'package:gwp/domain/providers/asset_price_provider.dart';

void main() {
  AssetQuote q(String s, String p) => AssetQuote(
        symbol: s, price: Decimal.parse(p), currency: 'USD',
        asOfTime: DateTime.utc(2025, 1, 1), source: 'test',
      );

  group('CompositeAssetPriceProvider', () {
    test('first provider succeeds immediately', () async {
      final p1 = FakeAssetPriceProvider(latest: q('A', '100'));
      final composite = CompositeAssetPriceProvider([p1]);
      final r = await composite.fetchLatest('A');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('100'));
    });

    test('falls through to second provider when first fails', () async {
      final p1 = FakeAssetPriceProvider();
      final p2 = FakeAssetPriceProvider(latest: q('A', '200'));
      final composite = CompositeAssetPriceProvider([p1, p2]);
      final r = await composite.fetchLatest('A');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('200'));
    });

    test('circuit breaker opens after 5 consecutive failures', () async {
      final clock = _FakeClock();
      final p1 = FakeAssetPriceProvider();
      final composite = CompositeAssetPriceProvider([p1], clock: () => clock.now);
      for (var i = 0; i < 5; i++) {
        await composite.fetchLatest('A');
        clock.advance(const Duration(seconds: 1));
      }
      await composite.fetchLatest('A');
      expect(p1.latestCalls, 5);
    });

    test('circuit breaker resets after cooldown', () async {
      final clock = _FakeClock();
      final p1 = FakeAssetPriceProvider();
      final composite = CompositeAssetPriceProvider([p1], clock: () => clock.now);
      for (var i = 0; i < 5; i++) {
        await composite.fetchLatest('A');
        clock.advance(const Duration(seconds: 1));
      }
      expect(p1.latestCalls, 5);
      clock.advance(const Duration(minutes: 6));
      await composite.fetchLatest('A');
      expect(p1.latestCalls, 6);
    });

    test('successful call resets breaker', () async {
      final clock = _FakeClock();
      final p1 = FakeAssetPriceProvider();
      final p2 = FakeAssetPriceProvider(latest: q('A', '100'));
      final composite = CompositeAssetPriceProvider([p1, p2], clock: () => clock.now);
      for (var i = 0; i < 3; i++) {
        await composite.fetchLatest('A');
      }
      expect(p2.latestCalls, greaterThan(0));
    });

    test('empty provider list returns error', () async {
      final composite = CompositeAssetPriceProvider([]);
      final r = await composite.fetchLatest('A');
      expect(r.isErr, isTrue);
    });

    test('fetchTimeSeries 失败不计入 fetchLatest 熔断器（Bug 16）', () async {
      final clock = _FakeClock();
      // Provider that fails fetchTimeSeries but succeeds fetchLatest
      final p1 = _FailingSeriesProvider(latest: q('A', '100'));
      final composite = CompositeAssetPriceProvider([p1], clock: () => clock.now);

      // Fail fetchTimeSeries 5+ times (enough to trip old shared breaker)
      for (var i = 0; i < 6; i++) {
        await composite.fetchTimeSeries(
          symbol: 'A',
          from: DateTime.utc(2025, 1, 1),
          to: DateTime.utc(2025, 1, 30),
        );
        clock.advance(const Duration(seconds: 1));
      }

      // fetchLatest should still work (its breaker is independent)
      final r = await composite.fetchLatest('A');
      expect(r.isOk, isTrue,
          reason: 'fetchTimeSeries 失败不应开启 fetchLatest 的熔断器');
    });
  });
}

class FakeAssetPriceProvider implements AssetPriceProvider {
  FakeAssetPriceProvider({this.latest});
  AssetQuote? latest;
  int latestCalls = 0;

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    latestCalls++;
    if (latest == null) return const Err(UnknownError('no data'));
    return Ok(latest!);
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async => const Err(UnknownError('not implemented'));
}

class _FakeClock {
  DateTime now = DateTime.utc(2025, 1, 1);
  void advance(Duration d) => now = now.add(d);
}

/// Provider that always fails fetchTimeSeries but succeeds fetchLatest.
class _FailingSeriesProvider implements AssetPriceProvider {
  _FailingSeriesProvider({required this.latest});
  final AssetQuote latest;

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async =>
      Ok(latest);

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async =>
      const Err(UnknownError('series always fails'));
}
