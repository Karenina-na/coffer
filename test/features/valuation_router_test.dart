import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/core/result.dart';
import 'package:coffer/domain/entities/asset.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/valuation/asset_valuator.dart';
import 'package:coffer/domain/valuation/valuation_router.dart';

final _now = DateTime.utc(2025, 1, 1);

Asset _asset(AssetType type, {String id = 'a1', String? code}) => Asset(
      id: id,
      accountId: 'acc',
      assetType: type,
      assetCode: code,
      quantity: Decimal.one,
      currency: 'USD',
      status: AssetStatus.holding,
      createdAt: _now,
      updatedAt: _now,
    );

AssetQuote _quote(String symbol, String price) => AssetQuote(
      symbol: symbol,
      price: Decimal.parse(price),
      currency: 'USD',
      asOfTime: _now,
      source: 'test',
    );

class _FakeValuator implements AssetValuator {
  _FakeValuator({
    required this.supportedTypes,
    AssetQuote? quote,
    AssetPriceSeries? series,
  })  : _quote = quote,
        _series = series;

  final Set<AssetType> supportedTypes;
  final AssetQuote? _quote;
  final AssetPriceSeries? _series;

  @override
  bool supports(Asset asset) => supportedTypes.contains(asset.assetType);

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    if (_quote != null) return Ok(_quote);
    return const Err(UnknownError('no quote'));
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    if (_series != null) return Ok(_series);
    return const Err(UnknownError('no history'));
  }
}

void main() {
  group('AssetValuationRouter', () {
    test('routes stock to first matching valuator', () async {
      final v = _FakeValuator(
        supportedTypes: {AssetType.stock},
        quote: _quote('AAPL', '150'),
      );
      final router = AssetValuationRouter([v]);

      final r = await router.valueNow(_asset(AssetType.stock, code: 'AAPL'));
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('150'));
    });

    test('routes cd to cd valuator', () async {
      final v = _FakeValuator(
        supportedTypes: {AssetType.cd},
        quote: _quote('cd', '10000'),
      );
      final router = AssetValuationRouter([v]);

      final r = await router.valueNow(_asset(AssetType.cd));
      expect(r.isOk, isTrue);
    });

    test('routes bond to bond valuator', () async {
      final v = _FakeValuator(
        supportedTypes: {AssetType.bond},
        quote: _quote('bond', '99.5'),
      );
      final router = AssetValuationRouter([v]);

      final r = await router.valueNow(_asset(AssetType.bond));
      expect(r.isOk, isTrue);
    });

    test('falls through to second valuator when first does not support', () async {
      final v1 = _FakeValuator(supportedTypes: {AssetType.stock});
      final v2 = _FakeValuator(
        supportedTypes: {AssetType.fund},
        quote: _quote('FUND', '50'),
      );
      final router = AssetValuationRouter([v1, v2]);

      final r = await router.valueNow(_asset(AssetType.fund));
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('50'));
    });

    test('unsupported type returns NotFoundError', () async {
      final v = _FakeValuator(supportedTypes: {AssetType.stock});
      final router = AssetValuationRouter([v]);

      final r = await router.valueNow(_asset(AssetType.policy));
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('supports() returns false when no valuator matches', () {
      final v = _FakeValuator(supportedTypes: {AssetType.stock});
      final router = AssetValuationRouter([v]);

      expect(router.supports(_asset(AssetType.crypto)), isFalse);
    });

    test('history routing delegates to matching valuator', () async {
      final series = AssetPriceSeries(
        symbol: 'AAPL',
        currency: 'USD',
        source: 'test',
        points: [
          AssetPricePoint(t: _now, price: Decimal.parse('150'), currency: 'USD'),
        ],
      );
      final v = _FakeValuator(
        supportedTypes: {AssetType.stock},
        series: series,
      );
      final router = AssetValuationRouter([v]);

      final r = await router.valueHistory(
        _asset(AssetType.stock),
        from: _now.subtract(const Duration(days: 30)),
        to: _now,
      );
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.points.length, 1);
    });
  });
}
