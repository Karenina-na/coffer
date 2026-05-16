import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/asset_type_info.dart';
import 'package:gwp/domain/valuation/asset_valuator.dart';
import 'package:gwp/domain/valuation/strategies/fixed_income_valuator.dart';

void main() {
  /// Build a CD asset with the given typeInfo and a fixed creation time.
  Asset _cd({
    required DateTime createdAt,
    required AssetTypeInfo typeInfo,
    String currency = 'CNY',
    Decimal? quantity,
  }) {
    return Asset(
      id: 'test-cd',
      accountId: 'acc-1',
      assetType: AssetType.cd,
      quantity: quantity ?? Decimal.one,
      currency: currency,
      status: AssetStatus.holding,
      createdAt: createdAt,
      updatedAt: createdAt,
      extInfo: typeInfo.toJson(),
    );
  }

  // ── Helper: make a CD with fixed income params ──
  Asset _fiAsset({
    required AssetType type,
    required DateTime createdAt,
    Decimal? annualRate,
    DateTime? startDate,
    DateTime? maturityDate,
    String? compounding,
    int? dayCount,
  }) {
    return _cd(
      createdAt: createdAt,
      typeInfo: FixedIncomeInfo(
        annualRate: annualRate,
        startDate: startDate,
        maturityDate: maturityDate,
        compounding: compounding,
        dayCount: dayCount,
      ),
    );
  }

  group('FixedIncomeValuator CD', () {
    // ── Simple interest ──

    test('简单计息：完整一年', () async {
      final now = DateTime.utc(2026, 1, 1);
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.035'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      final quote = result.valueOrNull!;
      // 3.5% simple interest for 1 full year: 1 + 0.035 = 1.035
      expect(quote.price, Decimal.parse('1.035'));
      expect(quote.currency, 'CNY');
      expect(quote.source, 'fixed-income-engine');
    });

    test('简单计息：半年', () async {
      final now = DateTime.utc(2025, 7, 1); // 181 days (Jan 1 to Jul 1 in non-leap)
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.0365'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      final quote = result.valueOrNull!;
      // 3.65% simple for ~181/365 year: ratio ≈ 0.0365 * 181/365 ≈ 0.0181
      // price ≈ 1.0181
      final price = quote.price;
      expect(price > Decimal.parse('1.018'), isTrue);
      expect(price < Decimal.parse('1.019'), isTrue);
    });

    test('简单计息：起息日缺省用 createdAt', () async {
      final now = DateTime.utc(2026, 1, 2); // 366 days after creation
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.0365'),
        compounding: 'simple',
        // no startDate — defaults to createdAt
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      final quote = result.valueOrNull!;
      // 3.65% simple for ~366/365 year: ratio ≈ 0.0366, price ≈ 1.0366
      expect(quote.price > Decimal.parse('1.036'), isTrue);
    });

    test('到期后停止计息', () async {
      final now = DateTime.utc(2026, 7, 1); // well past maturity
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.03'),
        startDate: DateTime.utc(2025, 1, 1),
        maturityDate: DateTime.utc(2025, 7, 1), // 181 day term
        compounding: 'simple',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      final quote = result.valueOrNull!;
      // 3% simple for ~181/365 year: ratio ≈ 0.03 * 181/365 ≈ 0.01488, price ≈ 1.01488
      // Should NOT accumulate beyond maturity
      final price = quote.price;
      expect(price > Decimal.parse('1.014'), isTrue);
      expect(price < Decimal.parse('1.015'), isTrue);
    });

    test('起息日之前价格为 1', () async {
      final now = DateTime.utc(2024, 6, 1);
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.05'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.price, Decimal.one);
    });

    test('利率为 0 时价格为 1', () async {
      final now = DateTime.utc(2026, 1, 1);
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.zero,
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.price, Decimal.one);
    });

    // ── Compounding modes ──

    test('按年复利', () async {
      final now = DateTime.utc(2027, 1, 1); // 2 years
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.05'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'annual',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      // (1+0.05)^2 = 1.1025, ratio = 0.1025, price = 1.1025
      expect(result.valueOrNull!.price, Decimal.parse('1.1025'));
    });

    test('按日复利', () async {
      final now = DateTime.utc(2026, 1, 1); // 365 days
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.0365'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'daily',
        dayCount: 365,
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      // daily: (1 + 0.0365/365)^365 - 1 ≈ e^0.0365 - 1 ≈ 1.0371 - 1 = 0.0371
      // price ≈ 1.0371 (approximately)
      final price = result.valueOrNull!.price;
      expect(price > Decimal.parse('1.037'), isTrue);
      expect(price < Decimal.parse('1.038'), isTrue);
    });

    test('按月复利', () async {
      final now = DateTime.utc(2026, 1, 1); // 365 days
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.06'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'monthly',
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final result = await valuator.valueNow(asset);

      expect(result.isOk, isTrue);
      // monthly: (1 + 0.06/12)^12 - 1 ≈ 0.06168, price ≈ 1.06168
      final price = result.valueOrNull!.price;
      expect(price > Decimal.parse('1.061'), isTrue);
      expect(price < Decimal.parse('1.062'), isTrue);
    });

    // ── Day count ──

    test('360 天计息基准比 365 积累更多利息', () async {
      final now = DateTime.utc(2026, 1, 1);
      final asset360 = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.036'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
        dayCount: 360,
      );
      final asset365 = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.036'),
        startDate: DateTime.utc(2025, 1, 1),
        compounding: 'simple',
        dayCount: 365,
      );

      final valuator = FixedIncomeValuator(clock: () => now);
      final r360 = await valuator.valueNow(asset360);
      final r365 = await valuator.valueNow(asset365);

      expect(r360.isOk, isTrue);
      expect(r365.isOk, isTrue);
      // 360-day basis: more interest accrues (days/360 > days/365)
      expect(
        r360.valueOrNull!.price > r365.valueOrNull!.price,
        isTrue,
      );
    });

    // ── Value history ──

    test('valueHistory 按日生成估值点', () async {
      final start = DateTime.utc(2025, 1, 1);
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: start,
        annualRate: Decimal.parse('0.0365'),
        startDate: start,
        compounding: 'simple',
        dayCount: 365,
      );

      final valuator = FixedIncomeValuator(clock: () => DateTime.utc(2025, 1, 10));
      final result = await valuator.valueHistory(
        asset,
        from: start,
        to: DateTime.utc(2025, 1, 5),
      );

      expect(result.isOk, isTrue);
      final series = result.valueOrNull!;
      // 5 days: Jan 1, 2, 3, 4, 5
      expect(series.points, hasLength(5));
      // Each day the price should increase slightly
      for (var i = 1; i < series.points.length; i++) {
        expect(
          series.points[i].price > series.points[i - 1].price,
          isTrue,
          reason: 'day ${i + 1} price should exceed day $i price',
        );
      }
    });

    // ── typeInfo integration ──

    test('从 Asset.typeInfo 正确读取固收参数', () {
      final asset = _fiAsset(
        type: AssetType.cd,
        createdAt: DateTime.utc(2025, 1, 1),
        annualRate: Decimal.parse('0.035'),
        startDate: DateTime.utc(2025, 1, 1),
        maturityDate: DateTime.utc(2026, 1, 1),
        compounding: 'simple',
        dayCount: 360,
      );

      final info = asset.typeInfo;
      expect(info, isA<FixedIncomeInfo>());
      final fi = info as FixedIncomeInfo;
      expect(fi.annualRate, Decimal.parse('0.035'));
      expect(fi.startDate, DateTime.utc(2025, 1, 1));
      expect(fi.maturityDate, DateTime.utc(2026, 1, 1));
      expect(fi.compounding, 'simple');
      expect(fi.dayCount, 360);
    });

    test('默认 CD 参数：simple 计息、365 计息基准', () {
      final asset = Asset(
        id: 'cd-default',
        accountId: 'acc-1',
        assetType: AssetType.cd,
        quantity: Decimal.one,
        currency: 'CNY',
        status: AssetStatus.holding,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        // no extInfo — should get defaults
      );

      final info = asset.typeInfo;
      expect(info, isA<FixedIncomeInfo>());
      final fi = info as FixedIncomeInfo;
      expect(fi.compounding, 'simple');
      expect(fi.dayCount, 365);
      expect(fi.annualRate, isNull); // no rate = zero in valuator
    });

    test('BOND 默认参数：annual 计息', () {
      final asset = Asset(
        id: 'bond-default',
        accountId: 'acc-1',
        assetType: AssetType.bond,
        quantity: Decimal.one,
        currency: 'CNY',
        status: AssetStatus.holding,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      final info = asset.typeInfo;
      expect(info, isA<FixedIncomeInfo>());
      final fi = info as FixedIncomeInfo;
      expect(fi.compounding, 'annual');
    });

    // ── supports ──

    test('supports CD 和 BOND，不 supports 其他', () {
      final valuator = FixedIncomeValuator();
      final cd = _fiAsset(type: AssetType.cd, createdAt: DateTime.utc(2025, 1, 1));
      final bond = _fiAsset(type: AssetType.bond, createdAt: DateTime.utc(2025, 1, 1));
      final stock = Asset(
        id: 's',
        accountId: 'a',
        assetType: AssetType.stock,
        quantity: Decimal.one,
        currency: 'CNY',
        status: AssetStatus.holding,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );
      final policy = Asset(
        id: 'p',
        accountId: 'a',
        assetType: AssetType.policy,
        quantity: Decimal.one,
        currency: 'CNY',
        status: AssetStatus.holding,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      expect(valuator.supports(cd), isTrue);
      expect(valuator.supports(bond), isTrue);
      expect(valuator.supports(stock), isFalse);
      expect(valuator.supports(policy), isFalse);
    });
  });
}
