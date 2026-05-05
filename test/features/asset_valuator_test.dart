import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/valuation/strategies/fixed_income_valuator.dart';
import 'package:gwp/domain/valuation/strategies/manual_valuator.dart';
import 'package:gwp/domain/valuation/strategies/market_quote_valuator.dart';
import 'package:gwp/domain/valuation/valuation_router.dart';
import 'package:gwp/domain/providers/asset_price_provider.dart';

import 'asset_valuator_test_helpers.dart';

void main() {
  final start = DateTime.utc(2025, 1, 1);
  final now = DateTime.utc(2026, 1, 1); // 2025 非闰年，恰好 365 天 = 1 年
  DateTime clock() => now;

  Asset mkAsset({
    required AssetType type,
    String? code,
    Map<String, dynamic>? ext,
    Decimal? currentPrice,
    String currency = 'CNY',
  }) => Asset(
    id: 'a1',
    accountId: 'acc',
    assetType: type,
    assetCode: code,
    quantity: Decimal.fromInt(1000),
    currentPrice: currentPrice,
    currency: currency,
    status: AssetStatus.holding,
    extInfo: ext,
    createdAt: start,
    updatedAt: start,
  );

  group('ManualValuator', () {
    test('supports 任意资产，读取 currentPrice', () async {
      final v = ManualValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.policy,
        currentPrice: Decimal.parse('123.45'),
      );
      expect(v.supports(a), isTrue);
      final r = await v.valueNow(a);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('123.45'));
      expect(r.valueOrNull!.currency, 'CNY');
      expect(r.valueOrNull!.source, 'manual');
    });

    test('currentPrice 缺失时回落 costPrice', () async {
      final v = ManualValuator(clock: clock);
      final a = Asset(
        id: 'a1',
        accountId: 'acc',
        assetType: AssetType.policy,
        quantity: Decimal.one,
        costPrice: Decimal.parse('99'),
        currency: 'USD',
        status: AssetStatus.holding,
        createdAt: start,
        updatedAt: start,
      );
      final r = await v.valueNow(a);
      expect(r.valueOrNull!.price, Decimal.parse('99'));
    });

    test('valueHistory 返回错误', () async {
      final v = ManualValuator(clock: clock);
      final r = await v.valueHistory(
        mkAsset(type: AssetType.policy, currentPrice: Decimal.one),
        from: start,
        to: now,
      );
      expect(r.isErr, isTrue);
    });
  });

  group('FixedIncomeValuator', () {
    test('CD 单利：一年 3% 净值 = 1.03', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        code: 'CD-001',
        ext: {
          'annualRate': 0.03,
          'startDate': start.toIso8601String(),
          'compounding': 'simple',
        },
      );
      expect(v.supports(a), isTrue);
      final r = await v.valueNow(a);
      expect(r.isOk, isTrue);
      final p = r.valueOrNull!.price.toDouble();
      expect(p, closeTo(1.03, 1e-9));
    });

    test('债券复利：一年 3% 年复利净值 ≈ 1.03', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.bond,
        ext: {
          'annualRate': 0.03,
          'startDate': start.toIso8601String(),
          'compounding': 'annual',
        },
      );
      final r = await v.valueNow(a);
      expect(r.valueOrNull!.price.toDouble(), closeTo(1.03, 1e-9));
    });

    test('到期后利息不再累计', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': 0.1,
          'startDate': start.toIso8601String(),
          'maturityDate': start
              .add(const Duration(days: 180))
              .toIso8601String(),
          'compounding': 'simple',
        },
      );
      // clock 是 1 年后；maturity 是 180 天后。利息上限 = 0.1 * 180/365
      final r = await v.valueNow(a);
      final expected = 1 + 0.1 * 180 / 365;
      expect(r.valueOrNull!.price.toDouble(), closeTo(expected, 1e-9));
    });

    test('不支持股票 / 基金', () {
      final v = FixedIncomeValuator(clock: clock);
      expect(v.supports(mkAsset(type: AssetType.stock, code: 'AAPL')), isFalse);
      expect(v.supports(mkAsset(type: AssetType.fund, code: 'VOO')), isFalse);
    });

    test('compounding 非字符串时按资产类型安全回落', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': '0.03',
          'startDate': start.toIso8601String(),
          'compounding': 1,
        },
      );

      final r = await v.valueNow(a);

      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('1.030000000000'));
    });

    test('Decimal 净值无 double 精度丢失：单利 10% × 1 年 精确 = 1.1', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': '0.1',
          'startDate': start.toIso8601String(),
          'compounding': 'simple',
        },
      );
      final r = await v.valueNow(a);
      // 与 1.1 完全相等（Decimal 精确），不依赖 closeTo
      expect(r.valueOrNull!.price, Decimal.parse('1.100000000000'));
    });

    test('日复利长期限：10 年 5% 净值 ≈ e^0.5 数量级，12 位精度稳定', () async {
      DateTime longClock() => start.add(const Duration(days: 3650));
      final v = FixedIncomeValuator(clock: longClock);
      final a = mkAsset(
        type: AssetType.bond,
        ext: {
          'annualRate': '0.05',
          'startDate': start.toIso8601String(),
          'compounding': 'daily',
        },
      );
      final r = await v.valueNow(a);
      // (1 + 0.05/365)^3650 ≈ 1.6486641...
      final p = r.valueOrNull!.price.toDouble();
      expect(p, closeTo(1.6486648220, 1e-8));
    });

    test('复利指数超上限时返回 ValidationError', () async {
      DateTime oneDayClock() => start.add(const Duration(days: 1));
      final v = FixedIncomeValuator(clock: oneDayClock);
      final a = mkAsset(
        type: AssetType.bond,
        ext: {
          'annualRate': '0.05',
          'dayCount': '0.000001',
          'startDate': start.toIso8601String(),
          'compounding': 'daily',
        },
      );
      final r = await v.valueNow(a);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('月复利半年期非整数幂：0.06 月复利 × 0.5 年', () async {
      DateTime halfClock() => start.add(const Duration(days: 182));
      final v = FixedIncomeValuator(clock: halfClock);
      final a = mkAsset(
        type: AssetType.bond,
        ext: {
          'annualRate': '0.06',
          'startDate': start.toIso8601String(),
          'compounding': 'monthly',
        },
      );
      final r = await v.valueNow(a);
      // t = 182/365 年，exp = 12 * t ≈ 5.98356
      // (1 + 0.06/12)^5.98356 ≈ 1.0302930
      final p = r.valueOrNull!.price.toDouble();
      expect(p, closeTo(1.0302930, 1e-6));
    });

    test('JPY 零利率：无论多久净值恒为 1.0', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        currency: 'JPY',
        ext: {
          'annualRate': 0,
          'startDate': start.toIso8601String(),
          'compounding': 'daily',
        },
      );
      final r = await v.valueNow(a);
      expect(r.valueOrNull!.price, Decimal.one);
    });

    test('起息日在未来：净值回落到 1.0 不爆负', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': '0.05',
          'startDate': DateTime.utc(2027, 1, 1).toIso8601String(),
          'compounding': 'simple',
        },
      );
      final r = await v.valueNow(a);
      expect(r.valueOrNull!.price, Decimal.one);
    });

    test('String 形式的 annualRate 和 dayCount 正确解析', () async {
      final v = FixedIncomeValuator(clock: clock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': '0.04',
          'dayCount': '360',
          'startDate': start.toIso8601String(),
          'compounding': 'simple',
        },
      );
      final r = await v.valueNow(a); // 单利 0.04 * (365/360) = 0.040555...
      final p = r.valueOrNull!.price.toDouble();
      expect(p, closeTo(1.04055555, 1e-7));
    });

    test('闰年 366 天 × dayCount=365：yearsHeld ≈ 366/365 单利放大', () async {
      // 2024-01-01 → 2025-01-01 横跨闰年 2024（有 2/29）= 实际 366 天
      final leapStart = DateTime.utc(2024, 1, 1);
      final leapNow = DateTime.utc(2025, 1, 1);
      DateTime leapClock() => leapNow;
      final v = FixedIncomeValuator(clock: leapClock);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': '0.05',
          'dayCount': '365',
          'startDate': leapStart.toIso8601String(),
          'compounding': 'simple',
        },
      );
      final r = await v.valueNow(a);
      // yearsHeld = 366/365 ≈ 1.00273972
      // 单利净值 = 1 + 0.05 * 366/365 ≈ 1.0501369863
      final p = r.valueOrNull!.price.toDouble();
      expect(p, closeTo(1.0501369863, 1e-8));
      // 与非闰年 1 年 (365 天) 的 1.05 结果明显不同，闰年多出的那一天必须体现
      expect(p, greaterThan(1.05));
    });
  });

  group('MarketQuoteValuator', () {
    test('命中缓存时不再触发远端', () async {
      final fake = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'AAPL', price: '200'),
      );
      final v = MarketQuoteValuator(source: fake, clock: clock);
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');
      final r1 = await v.valueNow(a);
      final r2 = await v.valueNow(a);
      expect(r1.valueOrNull!.price, Decimal.parse('200'));
      expect(r2.valueOrNull!.price, Decimal.parse('200'));
      expect(fake.latestCalls, 1);
    });

    test('forceRefresh=true 时跳过缓存直接请求远端', () async {
      final fake = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'AAPL', price: '200'),
      );
      final v = MarketQuoteValuator(source: fake, clock: clock);
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');
      await v.valueNow(a);
      expect(fake.latestCalls, 1);
      await v.valueNow(a, forceRefresh: true);
      expect(fake.latestCalls, 2);
    });

    test('forceRefresh=true 时历史序列也跳过缓存', () async {
      final fake = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: 'AAPL',
          currency: 'USD',
          points: [
            AssetPricePoint(
              t: DateTime.utc(2026, 1, 1),
              price: Decimal.parse('200'),
              currency: 'USD',
            ),
          ],
          source: 'fake',
        ),
      );
      final v = MarketQuoteValuator(source: fake, clock: clock);
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');
      await v.valueHistory(a, from: start, to: now);
      expect(fake.seriesCalls, 1);
      await v.valueHistory(a, from: start, to: now, forceRefresh: true);
      expect(fake.seriesCalls, 2);
    });

    test('ext_info.priceSymbol 覆盖 assetCode', () async {
      final fake = FakeAssetPriceProvider(
        latest: mkQuote(symbol: '0700.HK', price: '300'),
      );
      final v = MarketQuoteValuator(source: fake, clock: clock);
      final a = mkAsset(
        type: AssetType.stock,
        code: 'tencent',
        ext: {'priceSymbol': '0700.HK'},
      );
      await v.valueNow(a);
      expect(fake.lastSymbol, '0700.HK');
    });

    test('无代码无 priceSymbol 时 supports=false', () {
      final v = MarketQuoteValuator(
        source: FakeAssetPriceProvider(latest: mkQuote()),
        clock: clock,
      );
      expect(v.supports(mkAsset(type: AssetType.stock)), isFalse);
    });

    test('TTL 未过期再次 valueNow 命中缓存，TTL 过期后重新拉取', () async {
      DateTime t = DateTime.utc(2026, 1, 1, 10);
      DateTime tick() => t;
      final fake = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'AAPL', price: '200'),
      );
      final v = MarketQuoteValuator(
        source: fake,
        clock: tick,
        latestTtl: const Duration(minutes: 5),
      );
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');

      await v.valueNow(a);
      expect(fake.latestCalls, 1);

      // 4 分钟后：仍在 TTL 内，应命中缓存
      t = t.add(const Duration(minutes: 4));
      await v.valueNow(a);
      expect(fake.latestCalls, 1, reason: 'TTL 未过期不应再次远端');

      // 6 分钟后：超过 5 分钟 TTL，应重新拉取
      t = t.add(const Duration(minutes: 2));
      await v.valueNow(a);
      expect(fake.latestCalls, 2, reason: 'TTL 过期应触发新拉取');
    });

    test('历史序列 TTL 过期后重新拉取', () async {
      DateTime t = DateTime.utc(2026, 1, 1, 10);
      DateTime tick() => t;
      final fake = FakeAssetPriceProvider(
        series: AssetPriceSeries(
          symbol: 'AAPL',
          currency: 'USD',
          points: [
            AssetPricePoint(
              t: DateTime.utc(2025, 12, 31),
              price: Decimal.parse('200'),
              currency: 'USD',
            ),
          ],
          source: 'fake',
        ),
      );
      final v = MarketQuoteValuator(
        source: fake,
        clock: tick,
        historyTtl: const Duration(hours: 6),
      );
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');

      await v.valueHistory(a, from: start, to: now);
      expect(fake.seriesCalls, 1);

      // 5 小时后：仍在 TTL 内
      t = t.add(const Duration(hours: 5));
      await v.valueHistory(a, from: start, to: now);
      expect(fake.seriesCalls, 1);

      // 再过 2 小时（累计 7 小时）：TTL 过期
      t = t.add(const Duration(hours: 2));
      await v.valueHistory(a, from: start, to: now);
      expect(fake.seriesCalls, 2);
    });

    test('invalidate() 清空缓存后立刻重新拉取', () async {
      final fake = FakeAssetPriceProvider(
        latest: mkQuote(symbol: 'AAPL', price: '200'),
      );
      final v = MarketQuoteValuator(source: fake, clock: clock);
      final a = mkAsset(type: AssetType.stock, code: 'AAPL');

      await v.valueNow(a);
      expect(fake.latestCalls, 1);
      await v.valueNow(a); // 命中缓存
      expect(fake.latestCalls, 1);

      v.invalidate();
      await v.valueNow(a);
      expect(fake.latestCalls, 2);
    });
  });

  group('AssetValuationRouter', () {
    test('按注册顺序路由：CD → FixedIncome，而非 Manual', () async {
      final router = AssetValuationRouter([
        FixedIncomeValuator(clock: clock),
        ManualValuator(clock: clock),
      ]);
      final a = mkAsset(
        type: AssetType.cd,
        ext: {
          'annualRate': 0.05,
          'startDate': start.toIso8601String(),
          'compounding': 'simple',
        },
      );
      final r = await router.valueNow(a);
      expect(r.valueOrNull!.source, 'fixed-income-engine');
    });

    test('无匹配返回 NotFoundError', () async {
      final router = AssetValuationRouter([FixedIncomeValuator(clock: clock)]);
      final r = await router.valueNow(
        mkAsset(type: AssetType.policy, currentPrice: Decimal.one),
      );
      expect(r.isErr, isTrue);
    });
  });
}
