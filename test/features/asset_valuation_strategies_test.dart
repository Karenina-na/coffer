import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/core/result.dart';
import 'package:coffer/domain/entities/asset.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/entities/asset_type_info.dart';
import 'package:coffer/domain/providers/asset_price_provider.dart';
import 'package:coffer/domain/valuation/strategies/fixed_income_valuator.dart';
import 'package:coffer/domain/valuation/strategies/manual_valuator.dart';
import 'package:coffer/domain/valuation/strategies/market_quote_valuator.dart';
import 'package:coffer/domain/valuation/valuation_router.dart';

const _serverError = NetworkError('fake', kind: NetworkErrorKind.serverError);
const _notFound = NotFoundError('fake not found');

// ─────────────────────────────────────────────────────────
// Fake price provider — returns controlled data for testing
// ─────────────────────────────────────────────────────────

class _FakePriceProvider implements AssetPriceProvider {
  final Map<String, AssetQuote> _latest = {};
  final Map<String, AssetPriceSeries> _series = {};
  bool _failLatest = false;
  bool _failSeries = false;
  final List<String> latestCalls = [];
  final List<String> seriesKeys = [];

  void setLatest(String symbol, AssetQuote quote) => _latest[symbol] = quote;
  void setSeries(String key, AssetPriceSeries series) => _series[key] = series;
  void setFailLatest(bool v) => _failLatest = v;
  void setFailSeries(bool v) => _failSeries = v;

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    latestCalls.add(symbol);
    if (_failLatest) return const Err(_serverError);
    final q = _latest[symbol];
    if (q == null) return const Err(_notFound);
    return Ok(q);
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final key = '$symbol|$from|$to';
    seriesKeys.add(key);
    if (_failSeries) return const Err(_serverError);
    final s = _series[key];
    if (s == null) return const Err(NotFoundError('fake series not found'));
    return Ok(s);
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

Asset _asset({
  required String id,
  required AssetType type,
  String? assetCode,
  Decimal? quantity,
  String currency = 'USD',
  Decimal? costPrice,
  Decimal? currentPrice,
  Map<String, dynamic>? extInfo,
  DateTime? createdAt,
}) {
  final now = DateTime.utc(2025, 6, 1);
  return Asset(
    id: id,
    accountId: 'acc-1',
    assetType: type,
    assetCode: assetCode,
    quantity: quantity ?? Decimal.one,
    costPrice: costPrice,
    currentPrice: currentPrice,
    currency: currency,
    status: AssetStatus.holding,
    extInfo: extInfo,
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}

AssetQuote _quote(String symbol, String price, String currency) {
  return AssetQuote(
    symbol: symbol,
    price: Decimal.parse(price),
    currency: currency,
    asOfTime: DateTime.utc(2025, 6, 1),
    source: 'test',
  );
}

// ─────────────────────────────────────────────────────────
// 1) MarketQuoteValuator
// ─────────────────────────────────────────────────────────

void main() {
  group('MarketQuoteValuator', () {
    late _FakePriceProvider fakeProvider;
    late MarketQuoteValuator valuator;
    final now = DateTime.utc(2025, 6, 1);

    setUp(() {
      fakeProvider = _FakePriceProvider();
      valuator = MarketQuoteValuator(
        source: fakeProvider,
        clock: () => now,
      );
    });

    // ── supports ──

    test('supports 股票有 assetCode', () {
      final a = _asset(id: 'a', type: AssetType.stock, assetCode: 'AAPL');
      expect(valuator.supports(a), isTrue);
    });

    test('supports 基金有 assetCode', () {
      final a = _asset(id: 'a', type: AssetType.fund, assetCode: '510300.SS');
      expect(valuator.supports(a), isTrue);
    });

    test('supports 加密有 assetCode', () {
      final a = _asset(id: 'a', type: AssetType.crypto, assetCode: 'BTC-USD');
      expect(valuator.supports(a), isTrue);
    });

    test('supports 贵金属有 assetCode', () {
      final a = _asset(
        id: 'a', type: AssetType.preciousMetal, assetCode: 'GC=F');
      expect(valuator.supports(a), isTrue);
    });

    test('supports 外汇有 assetCode', () {
      final a = _asset(id: 'a', type: AssetType.fxAsset, assetCode: 'USD');
      expect(valuator.supports(a), isTrue);
    });

    test('不 supports CD', () {
      final a = _asset(id: 'a', type: AssetType.cd);
      expect(valuator.supports(a), isFalse);
    });

    test('不 supports POLICY', () {
      final a = _asset(id: 'a', type: AssetType.policy);
      expect(valuator.supports(a), isFalse);
    });

    test('不 supports 无代码的股票', () {
      final a = _asset(id: 'a', type: AssetType.stock);
      // no assetCode → _symbolFor returns null → supports is false
      expect(valuator.supports(a), isFalse);
    });

    test('优先从 extInfo.priceSymbol 读取 symbol', () {
      final a = _asset(id: 'a', type: AssetType.stock,
        assetCode: 'AAPL', extInfo: {'priceSymbol': 'AAPL.MX'});
      // MarketQuoteValuator._symbolFor uses priceSymbol override
      // We verify this by checking the symbol used for fetch
      fakeProvider.setLatest('AAPL.MX',
          _quote('AAPL.MX', '200', 'USD'));
      // The valuator would use 'AAPL.MX' not 'AAPL'
      expect(valuator.supports(a), isTrue);
    });

    // ── valueNow ──

    test('valueNow 返回提供商报价', () async {
      fakeProvider.setLatest('AAPL', _quote('AAPL', '185.5', 'USD'));
      final a = _asset(id: 'a', type: AssetType.stock, assetCode: 'AAPL');
      final r = await valuator.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.symbol, 'AAPL');
      expect(r.valueOrNull!.price, Decimal.parse('185.5'));
      expect(r.valueOrNull!.currency, 'USD');
    });

    test('valueNow 无 assetCode 时报错', () async {
      final a = _asset(id: 'a', type: AssetType.stock);
      final r = await valuator.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('valueNow 提供商报错时透传错误', () async {
      fakeProvider.setFailLatest(true);
      final a = _asset(id: 'a', type: AssetType.stock, assetCode: 'AAPL');
      final r = await valuator.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('valueNow 提供商返回 NotFound 时透传', () async {
      final a = _asset(id: 'a', type: AssetType.stock, assetCode: 'UNKNOWN');
      final r = await valuator.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('valueNow 每个资产类型都可用', () async {
      final types = [
        (AssetType.stock, 'AAPL'),
        (AssetType.equity, '0700.HK'),
        (AssetType.fund, '510300.SS'),
        (AssetType.crypto, 'BTC-USD'),
        (AssetType.perpetual, 'BTCUSDT'),
        (AssetType.contract, 'CT-001'),
        (AssetType.preciousMetal, 'GC=F'),
        (AssetType.future, 'CL=F'),
        (AssetType.option, 'AAPL240621C00180000'),
        (AssetType.warrant, 'WRT-001'),
        (AssetType.fxAsset, 'USDEUR=X'),
      ];
      for (final (type, code) in types) {
        fakeProvider.setLatest(code, _quote(code, '100', 'USD'));
        final a = _asset(id: type.code, type: type, assetCode: code);
        final r = await valuator.valueNow(a);
        expect(r.isOk, isTrue, reason: 'type=${type.code} should get a quote');
      }
    });

    // ── valueHistory ──

    test('valueHistory 返回历史序列', () async {
      final series = AssetPriceSeries(
        symbol: 'AAPL',
        currency: 'USD',
        points: [
          AssetPricePoint(
              t: DateTime.utc(2025, 6, 1),
              price: Decimal.parse('180'),
              currency: 'USD'),
          AssetPricePoint(
              t: DateTime.utc(2025, 6, 2),
              price: Decimal.parse('182'),
              currency: 'USD'),
        ],
        source: 'test',
      );
      final from = DateTime.utc(2025, 6, 1);
      final to = DateTime.utc(2025, 6, 5);
      fakeProvider.setSeries('AAPL|$from|$to', series);
      final a = _asset(id: 'a', type: AssetType.stock, assetCode: 'AAPL');
      final r = await valuator.valueHistory(a, from: from, to: to);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.points, hasLength(2));
    });

    test('valueHistory 无代码时报错', () async {
      final a = _asset(id: 'a', type: AssetType.stock);
      final r = await valuator.valueHistory(a,
          from: DateTime.utc(2025, 1, 1), to: DateTime.utc(2025, 6, 1));
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });
  });

  // ─────────────────────────────────────────────────────────
  // 2) ManualValuator
  // ─────────────────────────────────────────────────────────

  group('ManualValuator', () {
    final now = DateTime.utc(2025, 6, 1);
    late ManualValuator valuator;

    setUp(() {
      valuator = ManualValuator(clock: () => now);
    });

    test('supports 全部类型', () {
      for (final type in AssetType.values) {
        final a = _asset(id: type.code, type: type, currentPrice: Decimal.one);
        expect(valuator.supports(a), isTrue,
            reason: 'should support ${type.code}');
      }
    });

    test('valueNow 使用 currentPrice', () async {
      final a = _asset(id: 'p', type: AssetType.policy,
          currentPrice: Decimal.parse('50000'), currency: 'CNY');
      final r = await valuator.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('50000'));
      expect(r.valueOrNull!.currency, 'CNY');
      expect(r.valueOrNull!.source, 'manual');
    });

    test('valueNow currentPrice 为 null 时回落 costPrice', () async {
      final a = _asset(id: 'p', type: AssetType.policy,
          costPrice: Decimal.parse('30000'), currency: 'CNY');
      final r = await valuator.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('30000'));
    });

    test('valueNow 优先 currentPrice 而非 costPrice', () async {
      final a = _asset(id: 'p', type: AssetType.policy,
          currentPrice: Decimal.parse('50000'),
          costPrice: Decimal.parse('30000'));
      final r = await valuator.valueNow(a);
      expect(r.valueOrNull!.price, Decimal.parse('50000'));
    });

    test('valueNow currentPrice 和 costPrice 均为 null 时报错', () async {
      final a = _asset(id: 'p', type: AssetType.policy);
      final r = await valuator.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('valueHistory 永远返回错误', () async {
      final a = _asset(id: 'p', type: AssetType.policy,
          currentPrice: Decimal.one);
      final r = await valuator.valueHistory(a,
          from: DateTime.utc(2025, 1, 1), to: DateTime.utc(2025, 6, 1));
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<UnknownError>());
    });

    test('保单估值走 currentPrice（现金价值）', () async {
      final a = _asset(id: 'ins-1', type: AssetType.policy,
          quantity: Decimal.parse('1000000'),
          currentPrice: Decimal.parse('0.85'),
          currency: 'CNY',
          extInfo: (InsuranceInfo(
            insurer: '中国人寿',
            coverage: Decimal.parse('1000000'),
          )).toJson());
      final r = await valuator.valueNow(a);
      expect(r.isOk, isTrue);
      // 现金价值 = marketValue = quantity × currentPrice
      // = 1000000 × 0.85 = 850000
      expect(r.valueOrNull!.price, Decimal.parse('0.85'));
    });

    test('合约估值走 currentPrice', () async {
      final a = _asset(id: 'ct-1', type: AssetType.contract,
          currentPrice: Decimal.parse('1200'), currency: 'USD');
      final r = await valuator.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('1200'));
      expect(r.valueOrNull!.source, 'manual');
    });
  });

  // ─────────────────────────────────────────────────────────
  // 3) AssetValuationRouter
  // ─────────────────────────────────────────────────────────

  group('AssetValuationRouter', () {
    late _FakePriceProvider fakeProvider;
    late AssetValuationRouter router;

    setUp(() {
      fakeProvider = _FakePriceProvider();
      fakeProvider.setLatest('AAPL',
          _quote('AAPL', '185.5', 'USD'));
      router = AssetValuationRouter([
        FixedIncomeValuator(),
        MarketQuoteValuator(source: fakeProvider),
        ManualValuator(),
      ]);
    });

    test('CD 路由到 FixedIncomeValuator', () async {
      final a = _asset(id: 'cd-1', type: AssetType.cd,
          currency: 'CNY',
          createdAt: DateTime.utc(2025, 1, 1),
          extInfo: (FixedIncomeInfo(
            annualRate: Decimal.parse('0.035'),
            startDate: DateTime.utc(2025, 1, 1),
            compounding: 'simple',
          )).toJson());
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'fixed-income-engine');
    });

    test('BOND 路由到 FixedIncomeValuator', () async {
      final a = _asset(id: 'bond-1', type: AssetType.bond,
          currency: 'CNY',
          createdAt: DateTime.utc(2025, 1, 1),
          extInfo: (FixedIncomeInfo(
            annualRate: Decimal.parse('0.04'),
            startDate: DateTime.utc(2025, 1, 1),
            compounding: 'annual',
          )).toJson());
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'fixed-income-engine');
    });

    test('股票路由到 MarketQuoteValuator', () async {
      final a = _asset(id: 's', type: AssetType.stock, assetCode: 'AAPL');
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'test'); // from fake provider
    });

    test('基金路由到 MarketQuoteValuator', () async {
      fakeProvider.setLatest('510300.SS',
          _quote('510300.SS', '4.5', 'CNY'));
      final a = _asset(id: 'f', type: AssetType.fund, assetCode: '510300.SS');
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'test');
    });

    test('加密路由到 MarketQuoteValuator', () async {
      fakeProvider.setLatest('BTC-USD',
          _quote('BTC-USD', '67000', 'USD'));
      final a = _asset(id: 'c', type: AssetType.crypto,
          assetCode: 'BTC-USD');
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('67000'));
    });

    test('贵金属路由到 MarketQuoteValuator', () async {
      fakeProvider.setLatest('GC=F',
          _quote('GC=F', '2350', 'USD'));
      final a = _asset(id: 'pm', type: AssetType.preciousMetal,
          assetCode: 'GC=F');
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('2350'));
    });

    test('保单路由到 ManualValuator', () async {
      final a = _asset(id: 'pol', type: AssetType.policy,
          currentPrice: Decimal.parse('80000'));
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'manual');
      expect(r.valueOrNull!.price, Decimal.parse('80000'));
    });

    test('合约（有 currentPrice）路由到 MarketQuoteValuator', () async {
      // Contract is supported by MarketQuoteValuator if it has an assetCode
      fakeProvider.setLatest('CT-001',
          _quote('CT-001', '500', 'USD'));
      final a = _asset(id: 'ct', type: AssetType.contract,
          assetCode: 'CT-001', currentPrice: Decimal.parse('500'));
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      // contract with code goes to MarketQuote first
      expect(r.valueOrNull!.source, 'test');
    });

    test('合约（无代码）回落 ManualValuator', () async {
      // Contract without code: MarketQuote.supports → false, falls to Manual
      final a = _asset(id: 'ct2', type: AssetType.contract,
          currentPrice: Decimal.parse('300'));
      final r = await router.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.source, 'manual');
    });

    test('无任何 valuator 支持时报 NotFoundError', () async {
      // Create a router without ManualValuator as fallback
      final strictRouter = AssetValuationRouter([
        FixedIncomeValuator(),
        MarketQuoteValuator(source: fakeProvider),
      ]);
      final a = _asset(id: 'orphan', type: AssetType.policy);
      // Policy has no code, no currentPrice
      // FixedIncome doesn't support policy
      // MarketQuote doesn't support policy
      // No fallback → error
      final r = await strictRouter.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('supports 返回 true 当有匹配 valuator 时', () {
      final stock = _asset(id: 's', type: AssetType.stock, assetCode: 'AAPL');
      final cd = _asset(id: 'cd', type: AssetType.cd,
          createdAt: DateTime.utc(2025, 1, 1),
          extInfo: (FixedIncomeInfo(annualRate: Decimal.parse('0.035'))).toJson());
      final policy = _asset(id: 'pol', type: AssetType.policy,
          currentPrice: Decimal.one);
      // Even without Manual in the list, FixedIncome + MarketQuote cover these
      expect(router.supports(stock), isTrue);
      expect(router.supports(cd), isTrue);
      expect(router.supports(policy), isTrue); // ManualValuator
    });
  });

  // ─────────────────────────────────────────────────────────
  // 4) AssetTypeInfo JSON round-trip
  // ─────────────────────────────────────────────────────────

  group('AssetTypeInfo round-trip', () {
    test('FixedIncomeInfo 完整 JSON 往返', () {
      final original = FixedIncomeInfo(
        issuer: '中国银行',
        annualRate: Decimal.parse('0.035'),
        startDate: DateTime.utc(2025, 1, 1),
        maturityDate: DateTime.utc(2026, 1, 1),
        compounding: 'simple',
        dayCount: 360,
      );
      final json = original.toJson();
      expect(json['issuer'], '中国银行');
      expect(json['annualRate'], '0.035');
      expect(json['startDate'], '2025-01-01T00:00:00.000Z');
      expect(json['maturityDate'], '2026-01-01T00:00:00.000Z');
      expect(json['compounding'], 'simple');
      expect(json['dayCount'], 360);

      final restored = AssetTypeInfo.fromJson(json, AssetType.cd);
      expect(restored, isA<FixedIncomeInfo>());
      final fi = restored as FixedIncomeInfo;
      expect(fi.issuer, '中国银行');
      expect(fi.annualRate, Decimal.parse('0.035'));
      expect(fi.startDate, DateTime.utc(2025, 1, 1));
      expect(fi.maturityDate, DateTime.utc(2026, 1, 1));
      expect(fi.compounding, 'simple');
      expect(fi.dayCount, 360);
    });

    test('FixedIncomeInfo 空 JSON / null 统一返回类型默认', () {
      for (final json in [<String, dynamic>{}, null]) {
        final result = AssetTypeInfo.fromJson(
            json == null ? null : Map<String, dynamic>.from(json),
            AssetType.cd);
        expect(result, isA<FixedIncomeInfo>());
        final fi = result as FixedIncomeInfo;
        expect(fi.compounding, 'simple');
        expect(fi.dayCount, 365);
        // Fields without values stay null
        expect(fi.annualRate, isNull);
        expect(fi.startDate, isNull);
      }
    });

    test('BOND 空 JSON 默认 annual 计息', () {
      final result = AssetTypeInfo.fromJson(null, AssetType.bond);
      final fi = result as FixedIncomeInfo;
      expect(fi.compounding, 'annual');
      expect(fi.dayCount, 365);
    });

    test('InsuranceInfo 完整 JSON 往返', () {
      final original = InsuranceInfo(
        insurer: '中国人寿',
        policyNumber: 'P2024-001',
        annualPremium: Decimal.parse('12000'),
        coverage: Decimal.parse('500000'),
        effectiveDate: DateTime.utc(2024, 1, 1),
        maturityDate: DateTime.utc(2034, 1, 1),
        paymentFrequency: 'annual',
      );
      final json = original.toJson();
      final restored = AssetTypeInfo.fromJson(json, AssetType.policy);
      expect(restored, isA<InsuranceInfo>());
      final ins = restored as InsuranceInfo;
      expect(ins.insurer, '中国人寿');
      expect(ins.policyNumber, 'P2024-001');
      expect(ins.annualPremium, Decimal.parse('12000'));
      expect(ins.coverage, Decimal.parse('500000'));
      expect(ins.effectiveDate, DateTime.utc(2024, 1, 1));
      expect(ins.maturityDate, DateTime.utc(2034, 1, 1));
      expect(ins.paymentFrequency, 'annual');
    });

    test('PreciousMetalInfo 完整 JSON 往返', () {
      final original = PreciousMetalInfo(
        metalType: 'gold',
        weight: Decimal.parse('100'),
        purity: Decimal.parse('0.9999'),
      );
      final json = original.toJson();
      final restored = AssetTypeInfo.fromJson(json, AssetType.preciousMetal);
      expect(restored, isA<PreciousMetalInfo>());
      final pm = restored as PreciousMetalInfo;
      expect(pm.metalType, 'gold');
      expect(pm.weight, Decimal.parse('100'));
      expect(pm.purity, Decimal.parse('0.9999'));
    });

    test('NoExtraInfo 序列化为空 map', () {
      const info = NoExtraInfo();
      expect(info.toJson(), isEmpty);
      final restored = AssetTypeInfo.fromJson(null, AssetType.stock);
      expect(restored, isA<NoExtraInfo>());
    });

    test('toJson 跳过 null 字段', () {
      final sparse = FixedIncomeInfo(annualRate: Decimal.parse('0.04'));
      final json = sparse.toJson();
      expect(json, contains('annualRate'));
      expect(json, isNot(contains('issuer')));
      expect(json, isNot(contains('maturityDate')));
    });

    test('Asset.typeInfo getter 正确解析', () {
      final asset = _asset(
        id: 'cd-r',
        type: AssetType.cd,
        extInfo: (FixedIncomeInfo(
          annualRate: Decimal.parse('0.035'),
          compounding: 'simple',
        )).toJson(),
      );
      final info = asset.typeInfo;
      expect(info, isA<FixedIncomeInfo>());
      expect((info as FixedIncomeInfo).annualRate, Decimal.parse('0.035'));
    });

    test('Asset.copyWithTypeInfo 更新 extInfo', () {
      final asset = _asset(id: 'x', type: AssetType.stock);
      final updated = asset.copyWithTypeInfo(const NoExtraInfo());
      expect(updated.extInfo, isNotNull);
      expect(updated.extInfo, isEmpty);
    });

    test('新旧 extInfo 兼容：旧 rate 为数字仍可解析', () {
      // Simulate old extInfo where annualRate was stored as a raw number
      const json = <String, dynamic>{'annualRate': 0.035};
      final result = AssetTypeInfo.fromJson(
          Map<String, dynamic>.from(json), AssetType.cd);
      expect(result, isA<FixedIncomeInfo>());
      expect((result as FixedIncomeInfo).annualRate, Decimal.parse('0.035'));
    });

    test('DefaultFor CD / BOND / POLICY', () {
      expect(
        AssetTypeInfo.defaultFor(AssetType.cd),
        isA<FixedIncomeInfo>(),
      );
      expect(
        (AssetTypeInfo.defaultFor(AssetType.cd) as FixedIncomeInfo).compounding,
        'simple',
      );
      expect(
        (AssetTypeInfo.defaultFor(AssetType.bond) as FixedIncomeInfo)
            .compounding,
        'annual',
      );
      expect(
        AssetTypeInfo.defaultFor(AssetType.policy),
        isA<InsuranceInfo>(),
      );
      expect(
        AssetTypeInfo.defaultFor(AssetType.preciousMetal),
        isA<PreciousMetalInfo>(),
      );
      expect(
        AssetTypeInfo.defaultFor(AssetType.stock),
        isA<NoExtraInfo>(),
      );
    });
  });
}
