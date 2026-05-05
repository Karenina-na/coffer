import 'dart:convert';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_enums.dart';
import '../../domain/entities/asset_enums.dart';
import '../../domain/entities/asset_price_history_point.dart';
import '../../domain/entities/card_enums.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_enums.dart';
import '../../domain/entities/domain_event.dart';
import '../../domain/entities/event_enums.dart';
import '../../domain/events/event_bus.dart';
import '../../domain/repositories/account_channel_repository.dart';
import '../../domain/repositories/asset_cost_history_repository.dart';
import '../../domain/repositories/asset_price_history_repository.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/watched_pair_repository.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/create_asset.dart';
import '../../domain/usecases/create_card.dart';
import '../../domain/usecases/update_asset.dart';
import '../account/presentation/account_providers.dart';
import '../asset/presentation/asset_providers.dart';
import '../card/presentation/card_providers.dart';
import '../channel/presentation/channel_providers.dart';
import '../event/presentation/event_providers.dart';
import '../exchange_rate/presentation/exchange_rate_providers.dart';

/// 统计结果。
class SeedResult {
  const SeedResult({
    required this.accounts,
    required this.assets,
    required this.cards,
    required this.channels,
    required this.channelLinks,
    required this.events,
    required this.watchedPairs,
    required this.pricePoints,
    required this.costHistoryPoints,
    required this.errors,
    this.skipped = false,
  });

  /// 数据已存在、未执行注入的短路结果。
  factory SeedResult.alreadySeeded() => const SeedResult(
    accounts: 0,
    assets: 0,
    cards: 0,
    channels: 0,
    channelLinks: 0,
    events: 0,
    watchedPairs: 0,
    pricePoints: 0,
    costHistoryPoints: 0,
    errors: <String>[],
    skipped: true,
  );

  final int accounts;
  final int assets;
  final int cards;
  final int channels;
  final int channelLinks;
  final int events;
  final int watchedPairs;
  final int pricePoints;
  final int costHistoryPoints;
  final List<String> errors;

  /// 为 true 表示检测到库中已有资产，seeder 没有执行任何写入。
  final bool skipped;

  @override
  String toString() {
    if (skipped) return '检测到已有数据，跳过注入（如需强制请传 force=true）';
    return '账户 $accounts · 资产 $assets · 卡 $cards · '
        '通道 $channels ($channelLinks 连接) · 事件 $events · '
        '币对 $watchedPairs · 价格点 $pricePoints · 成本调整 $costHistoryPoints'
        '${errors.isEmpty ? '' : '\n错误: ${errors.length} 条'}';
  }
}

/// 测试种子所需的显式依赖集合，便于在单元测试中直接构造而不依赖 Riverpod。
class SeedDeps {
  const SeedDeps({
    required this.createAccount,
    required this.createAsset,
    required this.updateAsset,
    required this.createCard,
    required this.priceHistory,
    required this.costHistory,
    required this.channelRepo,
    required this.accountChannelRepo,
    required this.watchRepo,
    required this.eventRepo,
    required this.assets,
    required this.idGen,
    required this.now,
  });

  final CreateAccountUseCase createAccount;
  final CreateAssetUseCase createAsset;
  final UpdateAssetUseCase updateAsset;
  final CreateCardUseCase createCard;
  final AssetPriceHistoryRepository priceHistory;
  final AssetCostHistoryRepository costHistory;
  final ChannelRepository channelRepo;
  final AccountChannelRepository accountChannelRepo;
  final WatchedPairRepository watchRepo;
  final EventRepository eventRepo;
  final AssetRepository assets;
  final String Function() idGen;
  final DateTime Function() now;
}

/// Riverpod 入口：从 provider 解析依赖后委派给 [seedMockWithDeps]。
///
/// [force] 为 false（默认）时，若检测到库中已存在资产，将直接返回
/// [SeedResult.alreadySeeded]，避免重复触发产生大批唯一约束冲突。
Future<SeedResult> seedMockData(WidgetRef ref, {bool force = false}) {
  return seedMockWithDeps(
    SeedDeps(
      createAccount: ref.read(createAccountUseCaseProvider),
      createAsset: ref.read(createAssetUseCaseProvider),
      updateAsset: ref.read(updateAssetUseCaseProvider),
      createCard: ref.read(createCardUseCaseProvider),
      priceHistory: ref.read(assetPriceHistoryRepositoryProvider),
      costHistory: ref.read(assetCostHistoryRepositoryProvider),
      channelRepo: ref.read(channelRepositoryProvider),
      accountChannelRepo: ref.read(accountChannelRepositoryProvider),
      watchRepo: ref.read(watchedPairRepositoryProvider),
      eventRepo: ref.read(eventRepositoryProvider),
      assets: ref.read(assetRepositoryProvider),
      idGen: ref.read(uuidGeneratorProvider),
      now: DateTime.now,
    ),
    force: force,
  );
}

/// 核心：按部就班写入一批贴合真实日常使用的演示数据。
///
/// 覆盖面目标（全面升级版）：
/// - 账户：全部 7 种 [AccountType]，含多种 [AccountStatus]（active/dormant/inactive）
///         中国大陆 / 香港 / 美国 / 新加坡 / 英国 / 加密 全区域分布
/// - 资产：stock/equity/fund/bond/cd/option/warrant/policy/
///         crypto/perpetual/preciousMetal/fxAsset — 共 14 种，覆盖全部 AssetType
///         含持有/冻结/已赎回 等多种 AssetStatus
/// - 价格历史：90 天随机游走曲线（波动率各异：crypto ≫ stock ≫ bond）
/// - 成本历史：分批建仓 + 减仓 + 加仓全流程（stock/crypto/fund 各≥3次操作）
/// - 卡：8 张，覆盖 debit/credit/prepaid × VISA/MC/UNIONPAY/AMEX/JCB/DISCOVER/DINERS
///       expired / locked / active 三种状态，含/不含账单地址
/// - 通道：全 7 种协议（SWIFT/ACH/FPS/CNAPS/UK_FPS/SEPA/CHATS），含 disabled/maintenance
/// - 汇率币对：14 条，部分带上沿/下沿/变化幅度三档阈值
/// - 事件：覆盖全部 eventType × priority × handlingStatus × ackRequirement × ackStatus
///         共 18 条，含到期时间、batchId、refs 等辅助字段
Future<SeedResult> seedMockWithDeps(SeedDeps deps, {bool force = false}) async {
  // 幂等守卫：库中已有任何资产即视为已注入过，默认短路以避免大量 UNIQUE 冲突。
  if (!force) {
    final existing = await deps.assets.watchAll().first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => const [],
    );
    if (existing.isNotEmpty) {
      return SeedResult.alreadySeeded();
    }
  }
  final errors = <String>[];
  final now = deps.now();
  final uuid = deps.idGen;

  // ════════════════════════════════════════════════════════════════
  // 1. ACCOUNTS — 全部 7 种类型 × 6 地区 × 4 种状态
  // ════════════════════════════════════════════════════════════════
  final accountSpecs = <_AcctSpec>[
    // ── 银行 CN ──
    _AcctSpec('ICBC-6228', AccountType.bank, 'CN', '中国工商银行'),
    _AcctSpec('CMB-2020', AccountType.bank, 'CN', '招商银行'),
    _AcctSpec('BOC-8801', AccountType.bank, 'CN', '中国银行', status: AccountStatus.dormant),
    // ── 银行 HK ──
    _AcctSpec('HSBC-HK-9021', AccountType.bank, 'HK', 'HSBC Hong Kong'),
    _AcctSpec('BOCHK-4412', AccountType.bank, 'HK', '中银香港'),
    // ── 银行 US ──
    _AcctSpec('CHASE-0451', AccountType.bank, 'US', 'JPMorgan Chase'),
    _AcctSpec('SCHWAB-7731', AccountType.bank, 'US', 'Charles Schwab Bank'),
    // ── 银行 SG ──
    _AcctSpec('DBS-SG-3301', AccountType.bank, 'SG', 'DBS Bank Singapore'),
    // ── 银行 GB ──
    _AcctSpec('BARCLAYS-GB-5521', AccountType.bank, 'GB', 'Barclays UK'),
    // ── 支付 ──
    _AcctSpec('ALIPAY-188', AccountType.payment, 'CN', '支付宝'),
    _AcctSpec('WECHATPAY-298', AccountType.payment, 'CN', '微信支付'),
    _AcctSpec('PAYPAL-US', AccountType.payment, 'US', 'PayPal'),
    // ── 券商 ──
    _AcctSpec('FUTU-HK-03', AccountType.broker, 'HK', '富途证券'),
    _AcctSpec('IBKR-01', AccountType.broker, 'US', 'Interactive Brokers'),
    _AcctSpec('TIGER-SG-02', AccountType.broker, 'SG', '老虎证券', status: AccountStatus.inactive),
    // ── 加密交易所 ──
    _AcctSpec('BINANCE-01', AccountType.cryptoExchange, 'CRYPTO', 'Binance'),
    _AcctSpec('OKEX-02', AccountType.cryptoExchange, 'CRYPTO', 'OKX'),
    // ── 加密钱包 ──
    _AcctSpec('METAMASK-01', AccountType.cryptoWallet, 'CRYPTO', 'MetaMask'),
    _AcctSpec('LEDGER-HW-01', AccountType.cryptoWallet, 'CRYPTO', 'Ledger Hardware Wallet'),
    // ── 保险 ──
    _AcctSpec('PINGAN-LIFE', AccountType.insurance, 'CN', '平安人寿'),
    _AcctSpec('AIA-HK-88', AccountType.insurance, 'HK', 'AIA Hong Kong'),
    // ── 托管 ──
    _AcctSpec('FIDELITY-CUSTODY', AccountType.custody, 'US', 'Fidelity Investments'),
    _AcctSpec('HKEX-CCASS', AccountType.custody, 'HK', '香港中央结算（CCASS）'),
  ];

  final accountIds = <String, String>{};
  var accountCount = 0;
  for (final s in accountSpecs) {
    final r = await deps.createAccount(
      accountType: s.type,
      sovereigntyRegion: s.region,
      institutionName: s.institution,
      accountNo: s.accountNo,
      status: s.status,
    );
    r.when(
      ok: (a) {
        accountIds[s.accountNo] = a.id;
        accountCount++;
      },
      err: (e) => errors.add('account ${s.accountNo}: ${e.message}'),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 2. ASSETS — 覆盖全部 14 种 AssetType
  // ════════════════════════════════════════════════════════════════
  final assetRuntime = <_AssetRuntime>[];

  Future<void> addAsset(_AssetSpec s) async {
    final aid = accountIds[s.accountNo];
    if (aid == null) return;
    final r = await deps.createAsset(
      accountId: aid,
      assetType: s.type,
      quantity: Decimal.parse(s.qty),
      currency: s.currency,
      assetCode: s.code,
      costPrice: Decimal.parse(s.cost),
      currentPrice: Decimal.parse(s.price),
    );
    r.when(
      ok: (a) => assetRuntime.add(
        _AssetRuntime(
          assetId: a.id,
          code: s.code,
          quantity: Decimal.parse(s.qty),
          costPrice: Decimal.parse(s.cost),
          currentPrice: Decimal.parse(s.price),
          currency: s.currency,
          volatility: s.volatility,
          type: s.type,
        ),
      ),
      err: (e) => errors.add('asset ${s.code}: ${e.message}'),
    );
  }

  // vol 说明: crypto ~0.04, stock ~0.015, fund ~0.010, bond/cd/fx 0.0
  final assetSpecs = <_AssetSpec>[
    // ── STOCK US（Robinhood/IBKR）──
    _AssetSpec('IBKR-01', AssetType.stock, 'AAPL', '80', '148.50', '211.30', 'USD', 0.014),
    _AssetSpec('IBKR-01', AssetType.stock, 'NVDA', '25', '410.00', '875.60', 'USD', 0.032),
    _AssetSpec('IBKR-01', AssetType.stock, 'TSLA', '20', '215.00', '248.90', 'USD', 0.036),
    _AssetSpec('IBKR-01', AssetType.stock, 'MSFT', '30', '275.00', '418.70', 'USD', 0.013),
    _AssetSpec('IBKR-01', AssetType.stock, 'GOOGL', '15', '130.00', '172.40', 'USD', 0.015),
    _AssetSpec('IBKR-01', AssetType.stock, 'AMZN', '12', '185.00', '196.20', 'USD', 0.016),
    // ── STOCK HK（富途）──
    _AssetSpec('FUTU-HK-03', AssetType.stock, '0700', '400', '305.00', '399.20', 'HKD', 0.021),
    _AssetSpec('FUTU-HK-03', AssetType.stock, '9988', '800', '82.00', '71.60', 'HKD', 0.026),
    _AssetSpec('FUTU-HK-03', AssetType.stock, '3690', '500', '135.00', '117.40', 'HKD', 0.029),
    _AssetSpec('FUTU-HK-03', AssetType.stock, '1810', '600', '12.50', '15.80', 'HKD', 0.033),
    // ── EQUITY（非上市股权 / 私募）──
    _AssetSpec('FIDELITY-CUSTODY', AssetType.equity, 'OPENAI-SERIES-D', '1000', '25.00', '38.00', 'USD', 0.0),
    _AssetSpec('FIDELITY-CUSTODY', AssetType.equity, 'BYTEDANCE-PRE-IPO', '500', '140.00', '155.00', 'USD', 0.0),
    // ── FUND（ETF + 公募）──
    _AssetSpec('IBKR-01', AssetType.fund, 'VOO', '25', '412.00', '508.50', 'USD', 0.010),
    _AssetSpec('IBKR-01', AssetType.fund, 'QQQ', '20', '375.00', '444.20', 'USD', 0.013),
    _AssetSpec('IBKR-01', AssetType.fund, 'ARKK', '50', '52.00', '44.80', 'USD', 0.025),
    _AssetSpec('CMB-2020', AssetType.fund, 'CSI300-ETF', '5000', '3.80', '4.12', 'CNY', 0.012),
    _AssetSpec('CMB-2020', AssetType.fund, 'HS300-A', '20000', '1.15', '1.28', 'CNY', 0.011),
    // ── BOND ──
    _AssetSpec('ICBC-6228', AssetType.bond, 'CN-GOV-10Y-2024', '50000', '100.00', '101.85', 'CNY', 0.002),
    _AssetSpec('HSBC-HK-9021', AssetType.bond, 'HK-GOVT-3Y', '30000', '100.00', '99.60', 'HKD', 0.002),
    _AssetSpec('FIDELITY-CUSTODY', AssetType.bond, 'US-TREASURY-10Y', '10000', '100.00', '96.40', 'USD', 0.003),
    // ── CD（存款凭证）──
    _AssetSpec('HSBC-HK-9021', AssetType.cd, 'USD-6M-CD-2024', '30000', '1.00', '1.026', 'USD', 0.0),
    _AssetSpec('CMB-2020', AssetType.cd, 'CNY-1Y-CD-2024', '100000', '1.00', '1.032', 'CNY', 0.0),
    _AssetSpec('DBS-SG-3301', AssetType.cd, 'SGD-3M-CD', '20000', '1.00', '1.010', 'SGD', 0.0),
    // ── OPTION（美式期权）──
    _AssetSpec('IBKR-01', AssetType.option, 'AAPL-240621-C200', '5', '3.20', '12.50', 'USD', 0.050),
    _AssetSpec('IBKR-01', AssetType.option, 'TSLA-240920-P220', '3', '8.50', '4.10', 'USD', 0.065),
    // ── WARRANT（港股权证）──
    _AssetSpec('FUTU-HK-03', AssetType.warrant, 'HSI-CALL-W25', '10000', '0.12', '0.19', 'HKD', 0.070),
    // ── POLICY（保险/年金）──
    _AssetSpec('PINGAN-LIFE', AssetType.policy, 'PA-ENDOW-PRIME-20Y', '1', '120000', '138500', 'CNY', 0.0),
    _AssetSpec('AIA-HK-88', AssetType.policy, 'AIA-WEALTH-PRO-15Y', '1', '50000', '59800', 'USD', 0.0),
    // ── CRYPTO（现货）──
    _AssetSpec('BINANCE-01', AssetType.crypto, 'BTC', '0.85', '46500', '62800', 'USD', 0.041),
    _AssetSpec('BINANCE-01', AssetType.crypto, 'ETH', '5.0', '2350', '3085', 'USD', 0.044),
    _AssetSpec('BINANCE-01', AssetType.crypto, 'BNB', '30', '280', '415', 'USD', 0.050),
    _AssetSpec('OKEX-02', AssetType.crypto, 'SOL', '60', '88', '158.20', 'USD', 0.062),
    _AssetSpec('OKEX-02', AssetType.crypto, 'DOT', '200', '6.50', '8.40', 'USD', 0.055),
    _AssetSpec('METAMASK-01', AssetType.crypto, 'ETH', '1.5', '2800', '3085', 'USD', 0.044),
    _AssetSpec('LEDGER-HW-01', AssetType.crypto, 'BTC', '0.15', '55000', '62800', 'USD', 0.041),
    // ── PERPETUAL（永续合约）──
    _AssetSpec('BINANCE-01', AssetType.perpetual, 'BTC-PERP', '0.1', '61500', '62800', 'USD', 0.060),
    _AssetSpec('OKEX-02', AssetType.perpetual, 'ETH-PERP', '1.0', '3050', '3085', 'USD', 0.055),
    // ── PRECIOUS METAL ──
    _AssetSpec('FIDELITY-CUSTODY', AssetType.preciousMetal, 'XAU', '8', '1900', '2318', 'USD', 0.012),
    _AssetSpec('FIDELITY-CUSTODY', AssetType.preciousMetal, 'XAG', '300', '23.50', '29.20', 'USD', 0.022),
    _AssetSpec('ICBC-6228', AssetType.preciousMetal, 'AU9999', '500', '420', '488', 'CNY', 0.012),
    // ── FX_ASSET（现金外汇持仓）──
    _AssetSpec('HSBC-HK-9021', AssetType.fxAsset, 'USD-CASH', '8000', '1.00', '1.00', 'USD', 0.0),
    _AssetSpec('BARCLAYS-GB-5521', AssetType.fxAsset, 'GBP-CASH', '5000', '1.00', '1.00', 'GBP', 0.0),
    _AssetSpec('DBS-SG-3301', AssetType.fxAsset, 'SGD-CASH', '15000', '1.00', '1.00', 'SGD', 0.0),
    _AssetSpec('BOCHK-4412', AssetType.fxAsset, 'CNH-CASH', '20000', '1.00', '1.00', 'CNH', 0.0),
  ];
  for (final s in assetSpecs) {
    await addAsset(s);
  }
  final assetCount = assetRuntime.length;

  // ════════════════════════════════════════════════════════════════
  // 3. PRICE HISTORY — 90 天随机游走，按资产波动率差异化
  // ════════════════════════════════════════════════════════════════
  var pricePointCount = 0;
  const days = 90;
  for (final a in assetRuntime) {
    if (a.volatility == 0) continue; // fx/cd/policy 无行情历史
    final rng = math.Random(a.assetId.hashCode ^ 0x5EED_CAFE);
    var price = a.currentPrice;
    final buffer = <AssetPriceHistoryPoint>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final sourceKey = '${a.assetId}:${_yyyymmdd(day)}:mock';
      final market = a.quantity * price;
      buffer.add(
        AssetPriceHistoryPoint(
          id: uuid(),
          assetId: a.assetId,
          price: price,
          marketValue: market,
          currency: a.currency,
          source: 'mock',
          triggerTime: day,
          sourceKey: sourceKey,
          rawPayload: jsonEncode({
            'price': price.toString(),
            'marketValue': market.toString(),
            'currency': a.currency,
            'source': 'mock',
          }),
          createdAt: now,
        ),
      );
      if (i < days - 1) {
        final u1 = (rng.nextDouble() + 1e-9).clamp(1e-9, 1.0);
        final u2 = rng.nextDouble();
        final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
        final factor = Decimal.parse(
          (1 + z * a.volatility).toStringAsFixed(6),
        );
        if (factor > Decimal.zero) {
          price = (price.toRational() / factor.toRational()).toDecimal(
            scaleOnInfinitePrecision: 6,
          );
        }
      }
    }
    for (final p in buffer.reversed) {
      final r = await deps.priceHistory.record(p);
      r.when(
        ok: (_) => pricePointCount++,
        err: (e) => errors.add('price ${a.code}@${_yyyymmdd(p.triggerTime)}: ${e.message}'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 4. COST HISTORY — 分批建仓 / 加仓 / 减仓（stock/fund/crypto/equity）
  //    每个标的模拟 3 轮操作：T-60 初始建仓 → T-30 加仓 → T-10 部分减仓
  // ════════════════════════════════════════════════════════════════
  var costHistoryCount = 0;
  final tradables = assetRuntime
      .where(
        (a) =>
            a.type == AssetType.stock ||
            a.type == AssetType.crypto ||
            a.type == AssetType.fund ||
            a.type == AssetType.equity,
      )
      .take(10)
      .toList();

  for (final a in tradables) {
    var current = (await deps.assets.findById(a.assetId)).valueOrNull;
    if (current == null) continue;

    // 第一轮：T-60 加仓 30%（模拟首次补仓）
    final addQty1 = a.quantity * Decimal.parse('0.30');
    final rng1 = math.Random(a.assetId.hashCode ^ 0xA1B2);
    final addPrice1 = (a.costPrice ?? a.currentPrice) *
        Decimal.parse((0.92 + rng1.nextDouble() * 0.16).toStringAsFixed(4));
    final newCost1 = _weightedAvg(
      q1: current.quantity,
      p1: current.costPrice,
      q2: addQty1,
      p2: addPrice1,
    );
    final after1 = current.copyWith(
      quantity: current.quantity + addQty1,
      costPrice: newCost1,
      updatedAt: now.subtract(const Duration(days: 60)),
    );
    final r1 = await deps.updateAsset(prev: current, next: after1);
    r1.when(
      ok: (_) => costHistoryCount++,
      err: (e) => errors.add('cost+1 ${a.code}: ${e.message}'),
    );
    current = (await deps.assets.findById(a.assetId)).valueOrNull;
    if (current == null) continue;

    // 第二轮：T-30 再加仓 20%
    final addQty2 = a.quantity * Decimal.parse('0.20');
    final rng2 = math.Random(a.assetId.hashCode ^ 0xC3D4);
    final addPrice2 = a.currentPrice *
        Decimal.parse((0.94 + rng2.nextDouble() * 0.12).toStringAsFixed(4));
    final newCost2 = _weightedAvg(
      q1: current.quantity,
      p1: current.costPrice,
      q2: addQty2,
      p2: addPrice2,
    );
    final after2 = current.copyWith(
      quantity: current.quantity + addQty2,
      costPrice: newCost2,
      updatedAt: now.subtract(const Duration(days: 30)),
    );
    final r2 = await deps.updateAsset(prev: current, next: after2);
    r2.when(
      ok: (_) => costHistoryCount++,
      err: (e) => errors.add('cost+2 ${a.code}: ${e.message}'),
    );
    current = (await deps.assets.findById(a.assetId)).valueOrNull;
    if (current == null) continue;

    // 第三轮：T-10 减仓 15%（部分止盈）
    final sellQty = current.quantity * Decimal.parse('0.15');
    final after3 = current.copyWith(
      quantity: current.quantity - sellQty,
      updatedAt: now.subtract(const Duration(days: 10)),
    );
    final r3 = await deps.updateAsset(prev: current, next: after3);
    r3.when(
      ok: (_) => costHistoryCount++,
      err: (e) => errors.add('cost- ${a.code}: ${e.message}'),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 5. CARDS — 8 张，覆盖所有 CardType × CardOrganization × CardStatus
  // ════════════════════════════════════════════════════════════════
  final expiredDate = DateTime(now.year - 1, now.month > 3 ? now.month - 3 : 1, 1);
  final criticalDate = now.add(const Duration(days: 18));  // < 30天到期
  final warningDate = now.add(const Duration(days: 65));   // < 90天到期

  final cardSpecs = <_CardSpec>[
    // 已过期借记卡
    _CardSpec(
      'CHASE-0451', 'VISA', '4111111111110451',
      CardType.debit, 'JPMorgan Chase',
      expiredDate.month, expiredDate.year, 'USD', null,
      status: CardStatus.expired,
    ),
    // 即将到期信用卡（需续签）
    _CardSpec(
      'CHASE-0451', 'AMEX', '378282246310005',
      CardType.credit, 'Chase AMEX',
      criticalDate.month, criticalDate.year, 'USD',
      '270 Park Ave, New York, NY 10172, USA',
    ),
    // 普通信用卡 CN
    _CardSpec(
      'ICBC-6228', 'MASTERCARD', '5555555555554444',
      CardType.credit, '工商银行双币信用卡',
      warningDate.month, warningDate.year, 'CNY',
      '北京市西城区复兴门内大街 55 号',
    ),
    // 长效借记卡 CN（银联）
    _CardSpec(
      'ICBC-6228', 'UNIONPAY', '6228480402564998',
      CardType.debit, '工商银行储蓄卡',
      10, now.year + 5, 'CNY', null,
    ),
    // HK VISA 借记
    _CardSpec(
      'HSBC-HK-9021', 'VISA', '4111111111111111',
      CardType.debit, 'HSBC HK Premier Debit',
      3, now.year + 4, 'HKD', null,
    ),
    // SG JCB 信用（含账单地址）
    _CardSpec(
      'DBS-SG-3301', 'JCB', '3566002020360505',
      CardType.credit, 'DBS JCB Platinum',
      8, now.year + 3, 'SGD', '12 Marina Blvd, Singapore 018982',
    ),
    // 礼品预付卡（有效 UnionPay 测试号）
    _CardSpec(
      'WECHATPAY-298', 'UNIONPAY', '6221558812340005',
      CardType.prepaid, '微信礼品卡',
      12, now.year + 1, 'CNY', null,
    ),
    // 已锁定借记卡（PayPal 风控冻结）
    _CardSpec(
      'PAYPAL-US', 'VISA', '4000056655665556',
      CardType.debit, 'PayPal Cash Card',
      6, now.year + 2, 'USD', null,
      status: CardStatus.locked,
    ),
    // GB Barclays DISCOVER（不常见组织，验证渲染）
    _CardSpec(
      'BARCLAYS-GB-5521', 'DISCOVER', '6011111111111117',
      CardType.credit, 'Barclays Rewards Credit',
      9, now.year + 4, 'GBP',
      '1 Churchill Place, London E14 5HP, UK',
    ),
    // CMB Diners（测试稀有卡组织）
    _CardSpec(
      'CMB-2020', 'DINERS', '30569309025904',
      CardType.credit, '招商银行 Diners Club',
      5, now.year + 3, 'CNY', '深圳市福田区益田路 6001 号',
    ),
  ];
  var cardCount = 0;
  final cardIds = <String, String>{};
  for (final s in cardSpecs) {
    final aid = accountIds[s.accountNo];
    if (aid == null) continue;
    final r = await deps.createCard(
      accountId: aid,
      cardOrganization: s.org,
      plainCardNo: s.plainNo,
      cardType: s.type,
      expireMonth: s.expMonth,
      expireYear: s.expYear,
      issuerName: s.issuer,
      currency: s.currency,
      billingAddress: s.billingAddress,
      status: s.status,
    );
    r.when(
      ok: (card) {
        cardCount++;
        // 以「发卡机构+账号」为唯一 key，避免同 org 多卡互相覆盖
        cardIds['${s.accountNo}:${s.org}'] = card.id;
      },
      err: (e) => errors.add('card ${s.org}: ${e.message}'),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 6. CHANNELS — 7 种协议，含 maintenance / disabled 状态
  // ════════════════════════════════════════════════════════════════
  final channelSpecs = <_ChannelSpec>[
    _ChannelSpec(
      key: 'SWIFT',
      channel: Channel(
        id: uuid(),
        name: 'SWIFT 环球银行电讯',
        transferProtocol: 'SWIFT',
        feeRate: Decimal.parse('0.001'),
        fixedFee: Decimal.parse('15'),
        limitCurrency: 'USD',
        dailyLimit: Decimal.parse('200000'),
        singleLimit: Decimal.parse('100000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['ICBC-6228', 'CHASE-0451', 'HSBC-HK-9021', 'BARCLAYS-GB-5521', 'DBS-SG-3301'],
    ),
    _ChannelSpec(
      key: 'ACH',
      channel: Channel(
        id: uuid(),
        name: 'ACH 美国自动清算',
        transferProtocol: 'ACH',
        feeRate: Decimal.zero,
        fixedFee: Decimal.zero,
        limitCurrency: 'USD',
        dailyLimit: Decimal.parse('50000'),
        singleLimit: Decimal.parse('25000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['CHASE-0451', 'IBKR-01', 'PAYPAL-US', 'SCHWAB-7731'],
    ),
    _ChannelSpec(
      key: 'FPS',
      channel: Channel(
        id: uuid(),
        name: '香港快速支付 FPS',
        transferProtocol: 'FPS',
        feeRate: Decimal.zero,
        limitCurrency: 'HKD',
        dailyLimit: Decimal.parse('1000000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['HSBC-HK-9021', 'BOCHK-4412', 'FUTU-HK-03'],
    ),
    _ChannelSpec(
      key: 'CNAPS',
      channel: Channel(
        id: uuid(),
        name: '人民币跨行支付 CNAPS',
        transferProtocol: 'CNAPS',
        feeRate: Decimal.zero,
        fixedFee: Decimal.parse('2'),
        limitCurrency: 'CNY',
        dailyLimit: Decimal.parse('50000'),
        singleLimit: Decimal.parse('20000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['ICBC-6228', 'CMB-2020', 'BOC-8801', 'ALIPAY-188', 'WECHATPAY-298'],
    ),
    _ChannelSpec(
      key: 'UK_FPS',
      channel: Channel(
        id: uuid(),
        name: '英国快速支付 Faster Payments',
        transferProtocol: 'UK_FPS',
        feeRate: Decimal.zero,
        limitCurrency: 'GBP',
        dailyLimit: Decimal.parse('250000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['BARCLAYS-GB-5521'],
    ),
    _ChannelSpec(
      key: 'SEPA',
      channel: Channel(
        id: uuid(),
        name: 'SEPA 欧元区单一支付',
        transferProtocol: 'SEPA',
        feeRate: Decimal.parse('0.0002'),
        limitCurrency: 'EUR',
        dailyLimit: Decimal.parse('100000'),
        // SEPA 当前维护中，测试 ChannelStatus.maintenance 渲染
        status: ChannelStatus.maintenance,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['BARCLAYS-GB-5521'],
    ),
    _ChannelSpec(
      key: 'CHATS',
      channel: Channel(
        id: uuid(),
        name: '香港美元结算 CHATS',
        transferProtocol: 'CHATS',
        feeRate: Decimal.parse('0.0001'),
        fixedFee: Decimal.parse('5'),
        limitCurrency: 'USD',
        dailyLimit: Decimal.parse('5000000'),
        singleLimit: Decimal.parse('1000000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
      memberAccountNos: ['HSBC-HK-9021', 'BOCHK-4412', 'HKEX-CCASS'],
    ),
  ];
  var channelCount = 0;
  var channelLinkCount = 0;
  final channelIds = <String, String>{};
  for (final spec in channelSpecs) {
    final r = await deps.channelRepo.upsert(spec.channel);
    r.when(
      ok: (_) {
        channelCount++;
        channelIds[spec.key] = spec.channel.id;
      },
      err: (e) => errors.add('channel ${spec.key}: ${e.message}'),
    );
    for (final accNo in spec.memberAccountNos) {
      final aid = accountIds[accNo];
      if (aid == null) continue;
      final link = await deps.accountChannelRepo.link(
        accountId: aid,
        channelId: spec.channel.id,
      );
      link.when(
        ok: (_) => channelLinkCount++,
        err: (e) => errors.add('channel-link ${spec.key}/$accNo: ${e.message}'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 7. WATCHED PAIRS — 14 条，部分带三档阈值
  // ════════════════════════════════════════════════════════════════
  //   (base, quote, threshHigh, threshLow, alertChangePct)
  final pairs = <(String, String, Decimal?, Decimal?, Decimal?)>[
    ('USD', 'CNY', Decimal.parse('7.35'), Decimal.parse('6.90'), Decimal.parse('1.0')),
    ('EUR', 'USD', Decimal.parse('1.12'), Decimal.parse('1.02'), Decimal.parse('0.8')),
    ('HKD', 'CNY', Decimal.parse('0.95'), Decimal.parse('0.88'), null),
    ('JPY', 'CNY', null, null, Decimal.parse('1.5')),
    ('GBP', 'USD', Decimal.parse('1.32'), null, Decimal.parse('1.0')),
    ('USD', 'SGD', Decimal.parse('1.40'), Decimal.parse('1.28'), null),
    ('AUD', 'USD', null, Decimal.parse('0.60'), null),
    ('EUR', 'CNY', null, null, Decimal.parse('1.2')),
    ('USD', 'HKD', Decimal.parse('7.85'), Decimal.parse('7.75'), null),
    ('BTC', 'USD', Decimal.parse('70000'), Decimal.parse('55000'), Decimal.parse('5.0')),
    ('ETH', 'USD', Decimal.parse('4000'), Decimal.parse('2500'), Decimal.parse('6.0')),
    ('SGD', 'CNY', null, null, Decimal.parse('1.0')),
    ('CAD', 'USD', null, Decimal.parse('0.70'), null),
    ('CHF', 'USD', Decimal.parse('1.15'), null, null),
  ];
  var pairCount = 0;
  for (final p in pairs) {
    final r = await deps.watchRepo.add(baseCurrency: p.$1, quoteCurrency: p.$2);
    await r.when(
      ok: (_) async {
        pairCount++;
        if (p.$3 != null || p.$4 != null || p.$5 != null) {
          await deps.watchRepo.updateThresholds(
            pairKey: '${p.$1}/${p.$2}',
            thresholdHigh: p.$3,
            thresholdLow: p.$4,
            alertChangePct: p.$5,
          );
        }
      },
      err: (e) async => errors.add('pair ${p.$1}/${p.$2}: ${e.message}'),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 8. EVENTS — 18 条，覆盖全部 eventType × priority × ackRequirement
  // ════════════════════════════════════════════════════════════════
  final btcAsset = assetRuntime.where((a) => a.code == 'BTC').firstOrNull;
  final ethAsset = assetRuntime.where((a) => a.code == 'ETH').firstOrNull;
  final aaplAsset = assetRuntime.where((a) => a.code == 'AAPL').firstOrNull;
  final nvdaAsset = assetRuntime.where((a) => a.code == 'NVDA').firstOrNull;
  final batchId = uuid(); // 同批次事件共享 batchId

  final eventSpecs = <DomainEvent>[
    // ── ASSET_PRICE_UPDATED (LOW / notApplicable / pending / resolved) ──
    if (aaplAsset != null)
      DomainEvent(
        id: uuid(),
        eventType: DomainEventTypes.assetPriceUpdated,
        relatedModel: RelatedModel.asset,
        relatedId: aaplAsset.assetId,
        sourceKey: '${DomainEventTypes.assetPriceUpdated}:${aaplAsset.assetId}:${_yyyymmdd(now)}',
        triggerTime: now.subtract(const Duration(minutes: 10)),
        priority: EventPriority.low,
        status: EventStatus.resolved,
        handlingStatus: HandlingStatus.handled,
        handler: 'yahoo',
        handlingNote: '价格已由 \$${aaplAsset.costPrice} 更新至 \$${aaplAsset.currentPrice}',
        ackRequirement: AckRequirement.notApplicable,
        ackStatus: AckStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    if (nvdaAsset != null)
      DomainEvent(
        id: uuid(),
        eventType: DomainEventTypes.assetPriceUpdated,
        relatedModel: RelatedModel.asset,
        relatedId: nvdaAsset.assetId,
        sourceKey: '${DomainEventTypes.assetPriceUpdated}:${nvdaAsset.assetId}:${_yyyymmdd(now)}',
        triggerTime: now.subtract(const Duration(minutes: 8)),
        priority: EventPriority.low,
        status: EventStatus.resolved,
        handlingStatus: HandlingStatus.handled,
        handler: 'eastmoney',
        ackRequirement: AckRequirement.notApplicable,
        ackStatus: AckStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),

    // ── ASSET_VALUATION_FAILED (HIGH / optional / pending / failed) ──
    if (btcAsset != null)
      DomainEvent(
        id: uuid(),
        eventType: DomainEventTypes.assetValuationFailed,
        relatedModel: RelatedModel.asset,
        relatedId: btcAsset.assetId,
        refs: {'stage': 'latest', 'provider': 'coinbase'},
        sourceKey: '${DomainEventTypes.assetValuationFailed}:${btcAsset.assetId}:${_yyyymmdd(now.subtract(const Duration(days: 1)))}:latest',
        triggerTime: now.subtract(const Duration(days: 1)),
        priority: EventPriority.high,
        status: EventStatus.triggered,
        handlingStatus: HandlingStatus.failed,
        handler: 'coinbase',
        handlingNote: jsonEncode({'reason': 'HTTP 429 Too Many Requests', 'symbol': 'BTC-USD'}),
        ackRequirement: AckRequirement.optional,
        ackStatus: AckStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    if (ethAsset != null)
      DomainEvent(
        id: uuid(),
        eventType: DomainEventTypes.assetValuationFailed,
        relatedModel: RelatedModel.asset,
        relatedId: ethAsset.assetId,
        refs: {'stage': 'timeseries', 'provider': 'yahoo'},
        sourceKey: '${DomainEventTypes.assetValuationFailed}:${ethAsset.assetId}:${_yyyymmdd(now.subtract(const Duration(days: 2)))}:timeseries',
        triggerTime: now.subtract(const Duration(days: 2)),
        priority: EventPriority.high,
        status: EventStatus.triggered,
        handlingStatus: HandlingStatus.failed,
        handler: 'yahoo',
        handlingNote: jsonEncode({'reason': '网络超时，已重试 3 次', 'symbol': 'ETH-USD'}),
        ackRequirement: AckRequirement.optional,
        ackStatus: AckStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),

    // ── ASSET_SYNC_OUTDATED (MEDIUM / optional / pending) ──
    DomainEvent(
      id: uuid(),
      eventType: DomainEventTypes.assetSyncOutdated,
      relatedModel: RelatedModel.asset,
      relatedId: 'aggregate',
      sourceKey: '${DomainEventTypes.assetSyncOutdated}:${_yyyymmdd(now)}',
      triggerTime: now.subtract(const Duration(hours: 2)),
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: jsonEncode({
        'thresholdDays': 3,
        'count': assetRuntime.length,
        'outdated': [
          for (final a in assetRuntime.where((x) => x.volatility > 0).take(5))
            {'id': a.assetId, 'code': a.code},
        ],
      }),
      ackRequirement: AckRequirement.optional,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),

    // ── RATE_ALERT — USD/CNY 突破上沿 (HIGH / required_ / pending) ──
    DomainEvent(
      id: uuid(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.account,
      relatedId: accountIds['ICBC-6228'] ?? 'none',
      refs: {'pair': 'USD/CNY', 'kind': 'high'},
      sourceKey: '${DomainEventTypes.rateAlert}:USD/CNY:${_yyyymmdd(now)}:high',
      triggerTime: now.subtract(const Duration(hours: 1)),
      priority: EventPriority.high,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: 'USD/CNY 最新 7.3512 突破上沿 7.35，今日涨幅 +0.38%',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),

    // ── RATE_ALERT — BTC/USD 跌穿下沿 (HIGH / required_ / confirmed) ──
    DomainEvent(
      id: uuid(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.asset,
      relatedId: btcAsset?.assetId ?? 'none',
      refs: {'pair': 'BTC/USD', 'kind': 'low'},
      sourceKey: '${DomainEventTypes.rateAlert}:BTC/USD:${_yyyymmdd(now.subtract(const Duration(days: 3)))}:low',
      triggerTime: now.subtract(const Duration(days: 3)),
      priority: EventPriority.high,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handler: 'user',
      handlingNote: 'BTC 跌至 57,200，低于阈值 55,000，已手动确认',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.confirmed,
      ackAt: now.subtract(const Duration(days: 3, hours: 2)),
      ackNote: '已了解，持仓不动',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3, hours: 2)),
    ),

    // ── RATE_ALERT — EUR/USD 变化幅度预警 (MEDIUM / optional / dismissed) ──
    DomainEvent(
      id: uuid(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.account,
      relatedId: accountIds['BARCLAYS-GB-5521'] ?? 'none',
      refs: {'pair': 'EUR/USD', 'kind': 'change'},
      sourceKey: '${DomainEventTypes.rateAlert}:EUR/USD:${_yyyymmdd(now.subtract(const Duration(days: 5)))}:change',
      triggerTime: now.subtract(const Duration(days: 5)),
      priority: EventPriority.medium,
      status: EventStatus.closed,
      handlingStatus: HandlingStatus.handled,
      handler: 'user',
      handlingNote: '24h 变化 -1.12%，超过 0.8% 阈值',
      ackRequirement: AckRequirement.optional,
      ackStatus: AckStatus.dismissed,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 4)),
    ),

    // ── EXCHANGE_RATE_INGESTED (LOW / notApplicable) ──
    DomainEvent(
      id: uuid(),
      eventType: DomainEventTypes.exchangeRateIngested,
      relatedModel: RelatedModel.account,
      relatedId: 'system',
      refs: {'source': 'frankfurter', 'pairs': '14'},
      sourceKey: '${DomainEventTypes.exchangeRateIngested}:frankfurter:${_yyyymmdd(now)}',
      triggerTime: now.subtract(const Duration(hours: 6)),
      priority: EventPriority.low,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handler: 'frankfurter',
      handlingNote: '成功摄取 14 个币对今日汇率快照',
      ackRequirement: AckRequirement.notApplicable,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),

    // ── CARD_EXPIRING — 即将到期 (MEDIUM / required_ / pending，带 dueAt) ──
    DomainEvent(
      id: uuid(),
      eventType: 'CARD_EXPIRING',
      relatedModel: RelatedModel.card,
      relatedId: cardIds['CHASE-0451:AMEX'] ?? 'none',
      sourceKey: 'CARD_EXPIRING:chase-amex:${_yyyymmdd(now.subtract(const Duration(days: 7)))}',
      triggerTime: now.subtract(const Duration(days: 7)),
      dueAt: now.add(const Duration(days: 18)), // 18 天内需确认
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: 'Chase AMEX 将于 ${criticalDate.month}/${criticalDate.year} 到期，请尽快申请续卡',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.pending,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
    ),

    // ── CARD_CREDIT_LOW — 余额不足 (LOW / optional / dismissed) ──
    DomainEvent(
      id: uuid(),
      eventType: 'CARD_CREDIT_LOW',
      relatedModel: RelatedModel.card,
      relatedId: cardIds['ICBC-6228:MASTERCARD'] ?? 'none',
      sourceKey: 'CARD_CREDIT_LOW:icbc-mc:${_yyyymmdd(now.subtract(const Duration(days: 4)))}',
      triggerTime: now.subtract(const Duration(days: 4)),
      priority: EventPriority.low,
      status: EventStatus.closed,
      handlingStatus: HandlingStatus.handled,
      handler: 'user',
      handlingNote: '可用额度已降至 ¥3,200，已临时调额，忽略本次提醒',
      ackRequirement: AckRequirement.optional,
      ackStatus: AckStatus.dismissed,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),

    // ── BALANCE_ANOMALY — Binance 余额骤降 (CRITICAL / required_ / pending) ──
    DomainEvent(
      id: uuid(),
      eventType: 'BALANCE_ANOMALY',
      relatedModel: RelatedModel.account,
      relatedId: accountIds['BINANCE-01'] ?? 'none',
      refs: {'asset': 'USDT', 'delta': '-18.3%'},
      sourceKey: 'BALANCE_ANOMALY:BINANCE-01:${_yyyymmdd(now)}',
      triggerTime: now.subtract(const Duration(minutes: 25)),
      priority: EventPriority.critical,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.processing,
      handler: 'system',
      handlingNote: 'Binance 账户 USDT 余额 24h 内下跌 18.3%，已触发异常监控',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),

    // ── CHANNEL_MAINTENANCE — SEPA 维护通知 (LOW / optional / pending) ──
    DomainEvent(
      id: uuid(),
      eventType: 'CHANNEL_MAINTENANCE',
      relatedModel: RelatedModel.channel,
      relatedId: channelIds['SEPA'] ?? 'none',
      sourceKey: 'CHANNEL_MAINTENANCE:SEPA:${_yyyymmdd(now)}',
      triggerTime: now.subtract(const Duration(hours: 4)),
      dueAt: now.add(const Duration(hours: 20)), // 预计维护结束时间
      priority: EventPriority.low,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: 'SEPA 通道计划于今日 22:00 — 次日 04:00 UTC 进行系统升级维护',
      ackRequirement: AckRequirement.optional,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),

    // ── TRANSFER_CONFIRMED — 一批汇款成功（batchId 聚合）(LOW / notApplicable) ──
    DomainEvent(
      id: uuid(),
      batchId: batchId,
      eventType: 'TRANSFER_CONFIRMED',
      relatedModel: RelatedModel.account,
      relatedId: accountIds['HSBC-HK-9021'] ?? 'none',
      refs: {'channel': 'CHATS', 'amount': '5000', 'currency': 'USD', 'target': 'BOCHK-4412'},
      sourceKey: 'TRANSFER_CONFIRMED:HSBC-HK:CHATS:${_yyyymmdd(now.subtract(const Duration(days: 2)))}',
      triggerTime: now.subtract(const Duration(days: 2)),
      priority: EventPriority.low,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handler: 'system',
      handlingNote: 'CHATS 转账 USD 5,000 → 中银香港已到账，到账时间 T+0',
      ackRequirement: AckRequirement.notApplicable,
      ackStatus: AckStatus.pending,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
    DomainEvent(
      id: uuid(),
      batchId: batchId,
      eventType: 'TRANSFER_CONFIRMED',
      relatedModel: RelatedModel.account,
      relatedId: accountIds['ICBC-6228'] ?? 'none',
      refs: {'channel': 'SWIFT', 'amount': '3000', 'currency': 'USD', 'target': 'CHASE-0451'},
      sourceKey: 'TRANSFER_CONFIRMED:ICBC:SWIFT:${_yyyymmdd(now.subtract(const Duration(days: 2)))}',
      triggerTime: now.subtract(const Duration(days: 2, hours: 1)),
      priority: EventPriority.low,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handler: 'system',
      handlingNote: 'SWIFT 汇款 USD 3,000 → JPMorgan Chase 已到账（T+2）',
      ackRequirement: AckRequirement.notApplicable,
      ackStatus: AckStatus.pending,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),

    // ── ACCOUNT_DORMANT — BOC 账户休眠 (MEDIUM / required_ / pending) ──
    DomainEvent(
      id: uuid(),
      eventType: 'ACCOUNT_DORMANT',
      relatedModel: RelatedModel.account,
      relatedId: accountIds['BOC-8801'] ?? 'none',
      sourceKey: 'ACCOUNT_DORMANT:BOC-8801:${_yyyymmdd(now.subtract(const Duration(days: 10)))}',
      triggerTime: now.subtract(const Duration(days: 10)),
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: '中国银行账户超过 12 个月无交易，已被标记为休眠账户，请及时激活',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.pending,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
    ),
  ];

  var eventCount = 0;
  for (final e in eventSpecs) {
    final r = await deps.eventRepo.record(e);
    r.when(
      ok: (_) => eventCount++,
      err: (err) => errors.add('event ${e.eventType}: ${err.message}'),
    );
  }

  return SeedResult(
    accounts: accountCount,
    assets: assetCount,
    cards: cardCount,
    channels: channelCount,
    channelLinks: channelLinkCount,
    events: eventCount,
    watchedPairs: pairCount,
    pricePoints: pricePointCount,
    costHistoryPoints: costHistoryCount,
    errors: errors,
  );
}

// ════════════════════════════════════════════════════════════════
// 辅助函数
// ════════════════════════════════════════════════════════════════

Decimal _weightedAvg({
  required Decimal q1,
  required Decimal? p1,
  required Decimal q2,
  required Decimal p2,
}) {
  final old = p1 ?? p2;
  final total = q1 + q2;
  if (total == Decimal.zero) return p2;
  final num = (q1 * old) + (q2 * p2);
  return (num.toRational() / total.toRational()).toDecimal(
    scaleOnInfinitePrecision: 6,
  );
}

String _yyyymmdd(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}';
}

// ════════════════════════════════════════════════════════════════
// 数据规格 DTO
// ════════════════════════════════════════════════════════════════

class _AcctSpec {
  const _AcctSpec(
    this.accountNo,
    this.type,
    this.region,
    this.institution, {
    this.status = AccountStatus.active,
  });
  final String accountNo;
  final AccountType type;
  final String region;
  final String institution;
  final AccountStatus status;
}

class _AssetSpec {
  const _AssetSpec(
    this.accountNo,
    this.type,
    this.code,
    this.qty,
    this.cost,
    this.price,
    this.currency,
    this.volatility,
  );
  final String accountNo;
  final AssetType type;
  final String code;
  final String qty;
  final String cost;
  final String price;
  final String currency;
  final double volatility;
}

class _AssetRuntime {
  const _AssetRuntime({
    required this.assetId,
    required this.code,
    required this.quantity,
    required this.costPrice,
    required this.currentPrice,
    required this.currency,
    required this.volatility,
    required this.type,
  });
  final String assetId;
  final String code;
  final Decimal quantity;
  final Decimal? costPrice;
  final Decimal currentPrice;
  final String currency;
  final double volatility;
  final AssetType type;
}

class _CardSpec {
  const _CardSpec(
    this.accountNo,
    this.org,
    this.plainNo,
    this.type,
    this.issuer,
    this.expMonth,
    this.expYear,
    this.currency,
    this.billingAddress, {
    this.status = CardStatus.active,
  });
  final String accountNo;
  final String org;
  final String plainNo;
  final CardType type;
  final String issuer;
  final int expMonth;
  final int expYear;
  final String currency;
  final String? billingAddress;
  final CardStatus status;
}

class _ChannelSpec {
  const _ChannelSpec({
    required this.key,
    required this.channel,
    required this.memberAccountNos,
  });
  final String key;
  final Channel channel;
  final List<String> memberAccountNos;
}
