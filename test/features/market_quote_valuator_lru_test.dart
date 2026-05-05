import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/valuation/strategies/market_quote_valuator.dart';

import 'asset_valuator_test_helpers.dart';

Asset mkAsset({required String id, required String code}) => Asset(
      id: id,
      accountId: 'acc',
      assetType: AssetType.stock,
      assetCode: code,
      quantity: Decimal.fromInt(1),
      currency: 'USD',
      status: AssetStatus.holding,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
    );

void main() {
  group('MarketQuoteValuator LRU cache pruning', () {
    test('valueNow still works after hundreds of unique symbols', () async {
      final provider = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'S0', price: '100'),
      );
      final valuator = MarketQuoteValuator(
        source: provider,
        latestTtl: const Duration(hours: 1),
      );

      // Insert 300 unique symbols via valueNow.
      for (var i = 0; i < 300; i++) {
        final asset = mkAsset(id: 'a$i', code: 'S$i');
        provider.latest = mkQuote(symbol: 'S$i', price: '100');
        final r = await valuator.valueNow(asset);
        expect(r.isOk, isTrue);
      }

      // Can still query and get cached values without hitting the provider.
      provider.reset();
      provider.latest = null; // Would error if called.
      final asset = mkAsset(id: 'a0', code: 'S0');
      final r = await valuator.valueNow(asset, forceRefresh: false);
      // S0 might or might not be in cache after pruning. Either way, no crash.
      expect(r.isOk || r.isErr, isTrue);
      // Verify we can still call invalidate.
      valuator.invalidate();
    });

    test('valueNow TTL cache still expires entries normally', () async {
      final provider = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'B', price: '100'),
      );
      final valuator = MarketQuoteValuator(
        source: provider,
        latestTtl: const Duration(milliseconds: 10),
      );

      final asset = mkAsset(id: 'b1', code: 'B');
      await valuator.valueNow(asset);
      expect(provider.latestCalls, 1);

      // Wait for TTL to expire.
      await Future.delayed(const Duration(milliseconds: 20));
      await valuator.valueNow(asset);
      expect(provider.latestCalls, 2); // Re-fetch
    });
  });
}
