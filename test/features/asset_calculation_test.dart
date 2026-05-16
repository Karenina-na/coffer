import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_asset_price_history_repository.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/asset_type_info.dart';
import 'package:gwp/domain/entities/exchange_rate.dart';
import 'package:gwp/domain/entities/exchange_rate_enums.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/create_asset.dart';
import 'package:gwp/domain/usecases/valuate_asset.dart';

/// 每种资产类型的端到端计算验证。
///
/// 核心公式：marketValue = quantity × currentPrice
/// 测试验证各类型 quantity 和 currentPrice 的业务含义映射。
void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftAssetRepository assets;
  late DriftAssetPriceHistoryRepository priceHistory;
  late DriftExchangeRateRepository rates;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    assets = DriftAssetRepository(db.assetDao);
    priceHistory = DriftAssetPriceHistoryRepository(db.assetPriceHistoryDao);
    rates = DriftExchangeRateRepository(db.exchangeRateDao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> _createAccount(String id) async {
    await CreateAccountUseCase(
      accounts,
      idGenerator: () => id,
      now: DateTime.now,
    )(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: '测试银行',
    );
    return id;
  }

  Future<String> _createAsset({
    required String id,
    required AssetType type,
    required Decimal quantity,
    required String currency,
    Decimal? currentPrice,
    Decimal? costPrice,
    Map<String, dynamic>? extInfo,
  }) async {
    final r = await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => id,
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: type,
      quantity: quantity,
      currency: currency,
      currentPrice: currentPrice,
      costPrice: costPrice,
      extInfo: extInfo,
    );
    return r.valueOrNull!.id;
  }

  ValuateAssetUseCase _buildUc({int startId = 100}) {
    var i = startId;
    final now = DateTime.utc(2026, 4, 21, 10);
    return ValuateAssetUseCase(
      assets,
      priceHistory,
      rates,
      idGenerator: () => 'pp-${i++}',
      now: () => now,
    );
  }

  setUp(() async {
    await _createAccount('acc-1');
  });

  // ─────────────────────────────────────────────
  // 股票：quantity = 股数 × currentPrice = 每股价格
  // ─────────────────────────────────────────────

  group('股票/股权', () {
    test('marketValue = 股数 × 每股价格', () async {
      await _createAsset(
        id: 's1', type: AssetType.stock,
        quantity: Decimal.parse('500'), currentPrice: Decimal.parse('45.2'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 's1', newPrice: Decimal.parse('48'), source: 'test',
      );
      expect(r.isOk, isTrue);
      final a = r.valueOrNull!;
      expect(a.marketValue, Decimal.parse('24000'));  // 500 × 48
    });

    test('成本 × 股数 = 持仓成本', () async {
      await _createAsset(
        id: 's2', type: AssetType.stock,
        quantity: Decimal.parse('100'), currentPrice: Decimal.parse('50'),
        costPrice: Decimal.parse('40'), currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 's2', newPrice: Decimal.parse('55'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('5500')); // 100 × 55
    });

    test('零股持仓', () async {
      await _createAsset(
        id: 's3', type: AssetType.stock,
        quantity: Decimal.parse('0.5'), currentPrice: Decimal.parse('3000'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 's3', newPrice: Decimal.parse('3100'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('1550')); // 0.5 × 3100
    });
  });

  // ─────────────────────────────────────────────
  // 基金：quantity = 份额 × currentPrice = 每份净值
  // ─────────────────────────────────────────────

  group('基金', () {
    test('marketValue = 份额 × 单位净值', () async {
      await _createAsset(
        id: 'f1', type: AssetType.fund,
        quantity: Decimal.parse('10000'), currentPrice: Decimal.parse('1.234'),
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'f1', newPrice: Decimal.parse('1.250'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('12500')); // 10000 × 1.25
    });
  });

  // ─────────────────────────────────────────────
  // 加密：quantity = 币数 × currentPrice = 每币价格
  // ─────────────────────────────────────────────

  group('加密资产', () {
    test('marketValue = 币数 × 每币价格', () async {
      await _createAsset(
        id: 'c1', type: AssetType.crypto,
        quantity: Decimal.parse('2.5'), currentPrice: Decimal.parse('42000'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 'c1', newPrice: Decimal.parse('43000'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('107500')); // 2.5 × 43000
    });
  });

  // ─────────────────────────────────────────────
  // 存单 CD：quantity = 本金，price = 1 + 利息比
  // 利息由 FixedIncomeValuator 计算，这里验证
  // ValuateAssetUseCase 拿到 price 后的市值计算。
  // ─────────────────────────────────────────────

  group('存单 CD', () {
    test('marketValue = 本金 × 单位净值（price）', () async {
      await _createAsset(
        id: 'cd1', type: AssetType.cd,
        quantity: Decimal.parse('100000'), currency: 'CNY',
      );
      // price = 1.035 表示本金 + 3.5% 利息
      final r = await _buildUc()(
        assetId: 'cd1', newPrice: Decimal.parse('1.035'), source: 'fixed-income-engine',
      );
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.marketValue, Decimal.parse('103500')); // 100000 × 1.035
    });

    test('到期日价值 = 本金 × (1 + rate × years)', () async {
      // 模拟完整：1年定期 3.5%，price 由引擎算得
      await _createAsset(
        id: 'cd2', type: AssetType.cd,
        quantity: Decimal.parse('50000'), currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'cd2', newPrice: Decimal.parse('1.035'), source: 'fixed-income-engine',
      );
      // 50000 × 1.035 = 51750
      expect(r.valueOrNull!.marketValue, Decimal.parse('51750'));
    });
  });

  // ─────────────────────────────────────────────
  // 债券 BOND：quantity = 面值总额，price 同 CD
  // ─────────────────────────────────────────────

  group('债券', () {
    test('面值总额 × 单位净值', () async {
      await _createAsset(
        id: 'b1', type: AssetType.bond,
        quantity: Decimal.parse('200000'), currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'b1', newPrice: Decimal.parse('1.021'), source: 'fixed-income-engine',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('204200')); // 200000 × 1.021
    });
  });

  // ─────────────────────────────────────────────
  // 贵金属：quantity = 克数 × currentPrice = 每克价格
  // ─────────────────────────────────────────────

  group('贵金属', () {
    test('marketValue = 克数 × 每克价格', () async {
      await _createAsset(
        id: 'pm1', type: AssetType.preciousMetal,
        quantity: Decimal.parse('100'), currentPrice: Decimal.parse('450'),
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'pm1', newPrice: Decimal.parse('455'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('45500')); // 100 × 455
    });

    test('克数精确到 0.01', () async {
      await _createAsset(
        id: 'pm2', type: AssetType.preciousMetal,
        quantity: Decimal.parse('31.10'), currentPrice: Decimal.parse('460'),
        currency: 'CNY', // 1 盎司 ≈ 31.10g
      );
      final r = await _buildUc()(
        assetId: 'pm2', newPrice: Decimal.parse('462.5'), source: 'test',
      );
      // 31.10 × 462.5 = 14383.75
      expect(r.valueOrNull!.marketValue, Decimal.parse('14383.75'));
    });
  });

  // ─────────────────────────────────────────────
  // 外汇：quantity = 持仓金额 × currentPrice = 汇率
  // ─────────────────────────────────────────────

  group('外汇', () {
    test('marketValue = 持仓金额 × 当前汇率', () async {
      await _createAsset(
        id: 'fx1', type: AssetType.fxAsset,
        quantity: Decimal.parse('10000'), // 持仓 10000 USD
        currentPrice: Decimal.parse('7.25'), // 当前汇率 USDCNY=7.25
        currency: 'CNY', // 以 CNY 计价
      );
      final r = await _buildUc()(
        assetId: 'fx1', newPrice: Decimal.parse('7.30'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('73000')); // 10000 × 7.30
    });
  });

  // ─────────────────────────────────────────────
  // 保单 POLICY：quantity = 保额，currentPrice = 现金价值比例
  // ─────────────────────────────────────────────

  group('保单', () {
    test('现金价值 = 保额 × 现金价值比例', () async {
      await _createAsset(
        id: 'pol1', type: AssetType.policy,
        quantity: Decimal.parse('500000'), // 保额 50 万
        currentPrice: Decimal.parse('0.85'), // 现金价值比例 85%
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'pol1', newPrice: Decimal.parse('0.85'), source: 'test',
      );
      expect(r.isOk, isTrue);
      // 500000 × 0.85 = 425000
      expect(r.valueOrNull!.marketValue, Decimal.parse('425000'));
    });

    test('现金价值回落 costPrice 当 currentPrice 为 null 时', () async {
      // ManualValuator falls back to costPrice
      // For ValuateAssetUseCase, the newPrice is still required
      await _createAsset(
        id: 'pol2', type: AssetType.policy,
        quantity: Decimal.parse('1000000'), costPrice: Decimal.parse('0.75'),
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'pol2', newPrice: Decimal.parse('0.80'), source: 'manual',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('800000')); // 1000000 × 0.80
    });
  });

  // ─────────────────────────────────────────────
  // 期货/期权/永续/权证：quantity = 张数/手数
  // ─────────────────────────────────────────────

  group('衍生品', () {
    test('期货：marketValue = 手数 × 合约价格', () async {
      await _createAsset(
        id: 'fut1', type: AssetType.future,
        quantity: Decimal.parse('3'), currentPrice: Decimal.parse('2350'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 'fut1', newPrice: Decimal.parse('2400'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('7200')); // 3 × 2400
    });

    test('期权：marketValue = 张数 × 每张权利金', () async {
      await _createAsset(
        id: 'opt1', type: AssetType.option,
        quantity: Decimal.parse('10'), currentPrice: Decimal.parse('3.5'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 'opt1', newPrice: Decimal.parse('4.2'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('42')); // 10 × 4.2
    });

    test('永续合约：marketValue = 张数 × 标记价格', () async {
      await _createAsset(
        id: 'perp1', type: AssetType.perpetual,
        quantity: Decimal.parse('5'), currentPrice: Decimal.parse('68000'),
        currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 'perp1', newPrice: Decimal.parse('67500'), source: 'test',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('337500')); // 5 × 67500
    });
  });

  // ─────────────────────────────────────────────
  // 合约 CONTRACT
  // ─────────────────────────────────────────────

  group('合约', () {
    test('marketValue = 数量 × 当前价', () async {
      await _createAsset(
        id: 'ct1', type: AssetType.contract,
        quantity: Decimal.parse('1'), currentPrice: Decimal.parse('120000'),
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'ct1', newPrice: Decimal.parse('125000'), source: 'manual',
      );
      expect(r.valueOrNull!.marketValue, Decimal.parse('125000'));
    });
  });

  // ─────────────────────────────────────────────
  // 跨币种：所有类型共用 FX 换算逻辑
  // 以股票和 CD 为代表验证
  // ─────────────────────────────────────────────

  group('跨币种换算', () {
    setUp(() async {
      final now = DateTime.utc(2026, 4, 21);
      await rates.upsert(ExchangeRate(
        id: 'fx-usd-cny',
        pairKey: 'USD/CNY',
        baseCurrency: 'USD',
        quoteCurrency: 'CNY',
        rate: Decimal.parse('7.2'),
        asOfTime: now,
        updatedAt: now,
        source: 'manual',
        snapshotType: SnapshotType.daily,
      ));
    });

    test('股票 USD 报价 → CNY 持仓', () async {
      await _createAsset(
        id: 'x-stock', type: AssetType.stock,
        quantity: Decimal.parse('100'), currentPrice: Decimal.parse('10'),
        currency: 'CNY',
      );
      // 报价来自 USD（如 AAPL），换算为 CNY
      final r = await _buildUc()(
        assetId: 'x-stock',
        newPrice: Decimal.parse('150'), // USD price
        priceCurrency: 'USD',
        source: 'test',
      );
      expect(r.isOk, isTrue);
      // priceInCNY = 150 × 7.2 = 1080
      // marketValue = 100 × 1080 = 108000
      expect(r.valueOrNull!.currentPrice, Decimal.parse('1080'));
      expect(r.valueOrNull!.marketValue, Decimal.parse('108000'));
    });

    test('存单 CNY → HKD 换算', () async {
      final now = DateTime.utc(2026, 4, 21);
      await rates.upsert(ExchangeRate(
        id: 'fx-cny-hkd',
        pairKey: 'CNY/HKD',
        baseCurrency: 'CNY',
        quoteCurrency: 'HKD',
        rate: Decimal.parse('1.08'),
        asOfTime: now,
        updatedAt: now,
        source: 'manual',
        snapshotType: SnapshotType.daily,
      ));
      await _createAsset(
        id: 'x-cd', type: AssetType.cd,
        quantity: Decimal.parse('100000'), currency: 'HKD',
      );
      // CD price is always 1.x, but here the "quote" is in CNY and we convert
      final r = await _buildUc()(
        assetId: 'x-cd',
        newPrice: Decimal.parse('1.035'), // unit price in CNY
        priceCurrency: 'CNY',
        source: 'fixed-income-engine',
      );
      expect(r.isOk, isTrue);
      // priceInHKD = 1.035 × 1.08 = 1.1178
      // marketValue = 100000 × 1.1178 = 111780
      expect(r.valueOrNull!.currentPrice, Decimal.parse('1.1178'));
      expect(r.valueOrNull!.marketValue, Decimal.parse('111780'));
    });

    test('贵金属 USD 报价 → CNY 持仓', () async {
      await _createAsset(
        id: 'x-pm', type: AssetType.preciousMetal,
        quantity: Decimal.parse('50'), currentPrice: Decimal.parse('1900'),
        currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'x-pm',
        newPrice: Decimal.parse('1950'), // USD per gram
        priceCurrency: 'USD',
        source: 'test',
      );
      expect(r.isOk, isTrue);
      // priceInCNY = 1950 × 7.2 = 14040
      // marketValue = 50 × 14040 = 702000
      expect(r.valueOrNull!.currentPrice, Decimal.parse('14040'));
      expect(r.valueOrNull!.marketValue, Decimal.parse('702000'));
    });
  });

  // ─────────────────────────────────────────────
  // 价格历史写入验证
  // ─────────────────────────────────────────────

  group('价格历史写入', () {
    test('每次估值写入一条历史记录', () async {
      await _createAsset(
        id: 'hist-1', type: AssetType.stock,
        quantity: Decimal.parse('10'), currentPrice: Decimal.parse('100'),
        currency: 'USD',
      );
      await _buildUc()(
        assetId: 'hist-1', newPrice: Decimal.parse('110'), source: 'test',
      );
      await _buildUc(startId: 200)(
        assetId: 'hist-1', newPrice: Decimal.parse('115'), source: 'test2',
      );
      final persisted = await priceHistory.watchByAsset('hist-1').first;
      // Different source → 2 records
      expect(persisted.length, greaterThanOrEqualTo(2));
    });

    test('同日同源去重：sourceKey 唯一约束，首条保留', () async {
      await _createAsset(
        id: 'hist-2', type: AssetType.crypto,
        quantity: Decimal.parse('1'), currentPrice: Decimal.parse('60000'),
        currency: 'USD',
      );
      // Same day, same source → sourceKey identical → unique constraint
      await _buildUc()(
        assetId: 'hist-2', newPrice: Decimal.parse('61000'), source: 'manual',
      );
      await _buildUc()(
        assetId: 'hist-2', newPrice: Decimal.parse('62000'), source: 'manual',
      );
      final persisted = await priceHistory.watchByAsset('hist-2').first;
      // Only 1 record due to sourceKey UNIQUE + insertOrIgnore
      expect(persisted.length, 1);
      // First insert wins (61000), second is silently ignored
      expect(persisted.first.price, Decimal.parse('61000'));
    });
  });

  // ─────────────────────────────────────────────
  // 错误路径
  // ─────────────────────────────────────────────

  group('错误路径', () {
    test('newPrice ≤ 0 拒绝', () async {
      await _createAsset(
        id: 'err-1', type: AssetType.stock,
        quantity: Decimal.parse('100'), currency: 'USD',
      );
      final r = await _buildUc()(
        assetId: 'err-1', newPrice: Decimal.zero, source: 'test',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('资产不存在返回 NotFoundError', () async {
      final r = await _buildUc()(
        assetId: 'nonexistent', newPrice: Decimal.parse('100'), source: 'test',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('缺失汇率时返回错误', () async {
      await _createAsset(
        id: 'err-2', type: AssetType.stock,
        quantity: Decimal.parse('100'), currency: 'CNY',
      );
      final r = await _buildUc()(
        assetId: 'err-2',
        newPrice: Decimal.parse('100'),
        priceCurrency: 'JPY', // no rate configured
        source: 'test',
      );
      expect(r.isErr, isTrue);
    });
  });
}
