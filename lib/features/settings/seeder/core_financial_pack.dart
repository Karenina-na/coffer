import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/account_type_info.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/entities/asset_type_info.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/exchange_rate_enums.dart';
import '../../../domain/events/event_bus.dart';
import 'context.dart';
import 'models.dart';
import 'util.dart';

Future<SeedResult> seedCoreFinancialPack(SeedAssemblyContext ctx) async {
  final deps = ctx.deps;
  final now = ctx.now;
  var accounts = 0;
  var assets = 0;
  var cards = 0;
  var channels = 0;
  var channelLinks = 0;
  var watchedPairs = 0;
  var rates = 0;
  var pricePoints = 0;
  var costHistoryPoints = 0;
  var events = 0;

  Future<void> addAccount({
    required String key,
    required String accountNo,
    required AccountType type,
    required String region,
    required String institution,
    AccountStatus status = AccountStatus.active,
    AccountTypeInfo? typeInfo,
    Decimal? fxSpreadPercent,
    Decimal? fxFixedFee,
  }) async {
    await ctx.collect(
      deps.createAccount(
        accountType: type,
        sovereigntyRegion: region,
        institutionName: institution,
        accountNo: accountNo,
        status: status,
        typeInfo: typeInfo,
        fxSpreadPercent: fxSpreadPercent,
        fxFixedFee: fxFixedFee,
      ),
      (dynamic a) {
        ctx.accountIds[key] = a.id as String;
        accounts++;
      },
      'account $key',
    );
  }

  await addAccount(
    key: 'cn_bank',
    accountNo: 'CMB-TEST-CN',
    type: AccountType.bank,
    region: 'CN',
    institution: '招商银行',
    typeInfo: const BankAccountInfo(
      swiftBic: 'CMBCCNBS',
      branchName: '深圳分行',
      accountSubtype: 'savings',
    ),
    fxSpreadPercent: Decimal.parse('0.3'),
  );
  await addAccount(
    key: 'us_broker',
    accountNo: 'IBKR-TEST-US',
    type: AccountType.broker,
    region: 'US',
    institution: 'Interactive Brokers',
    typeInfo: const BrokerAccountInfo(
      accountSubtype: 'margin',
      baseCurrency: 'USD',
      marginEnabled: true,
    ),
    fxSpreadPercent: Decimal.parse('0.2'),
    fxFixedFee: Decimal.parse('2'),
  );
  await addAccount(
    key: 'cn_payment',
    accountNo: 'WECHATPAY-DEMO',
    type: AccountType.payment,
    region: 'CN',
    institution: '微信支付',
    typeInfo: const PaymentAccountInfo(platform: 'wechat'),
  );
  await addAccount(
    key: 'cn_insurance',
    accountNo: 'PINGAN-LIFE-DEMO',
    type: AccountType.insurance,
    region: 'CN',
    institution: '平安人寿',
    typeInfo: const InsuranceAccountInfo(
      policyType: 'life',
      registrationNo: 'PICC-TEST-001',
    ),
  );
  await addAccount(
    key: 'hk_bank_dormant',
    accountNo: 'HSBC-HK-DORMANT',
    type: AccountType.bank,
    region: 'HK',
    institution: 'HSBC Hong Kong',
    status: AccountStatus.dormant,
    typeInfo: const BankAccountInfo(
      swiftBic: 'HSBCHKHH',
      accountSubtype: 'checking',
    ),
  );
  await addAccount(
    key: 'us_custody',
    accountNo: 'FIDELITY-CUSTODY-DEMO',
    type: AccountType.custody,
    region: 'US',
    institution: 'Fidelity Custody',
    typeInfo: const CustodyAccountInfo(
      custodianName: 'Fidelity Investments',
      accountStructure: 'segregated',
    ),
  );
  await addAccount(
    key: 'sg_broker_inactive',
    accountNo: 'TIGER-SG-INACTIVE',
    type: AccountType.broker,
    region: 'SG',
    institution: 'Tiger Brokers Singapore',
    status: AccountStatus.inactive,
    typeInfo: const BrokerAccountInfo(
      accountSubtype: 'cash',
      baseCurrency: 'SGD',
    ),
  );
  await addAccount(
    key: 'eu_bank_closed',
    accountNo: 'SEPA-CLOSED-EU',
    type: AccountType.bank,
    region: 'EU',
    institution: 'Deutsche Bank Europe',
    status: AccountStatus.closed,
    typeInfo: const BankAccountInfo(
      swiftBic: 'DEUTDEFF',
      iban: 'DE89370400440532013000',
      accountSubtype: 'checking',
    ),
  );
  await addAccount(
    key: 'crypto_exchange',
    accountNo: 'BINANCE-DEMO',
    type: AccountType.cryptoExchange,
    region: 'CRYPTO',
    institution: 'Binance',
    typeInfo: const CryptoExchangeInfo(
      hasApiKey: true,
      supportedNetworks: 'ERC20,TRC20,BEP20,BEP2',
    ),
  );
  await addAccount(
    key: 'crypto_wallet',
    accountNo: 'METAMASK-DEMO',
    type: AccountType.cryptoWallet,
    region: 'CRYPTO',
    institution: 'MetaMask',
    typeInfo: const CryptoWalletInfo(walletType: 'hot', chain: 'Ethereum'),
  );

  Future<void> addAsset({
    required String key,
    required String accountKey,
    required AssetType type,
    required String code,
    required String qty,
    required String cost,
    required String price,
    required String currency,
    AssetStatus status = AssetStatus.holding,
    AssetTypeInfo? typeInfo,
  }) async {
    final accountId = ctx.accountIds[accountKey];
    if (accountId == null) return;
    await ctx.collect(
      deps.createAsset(
        accountId: accountId,
        assetType: type,
        quantity: Decimal.parse(qty),
        currency: currency,
        assetCode: code,
        costPrice: Decimal.parse(cost),
        currentPrice: Decimal.parse(price),
        status: status,
        typeInfo: typeInfo,
      ),
      (dynamic a) {
        ctx.assetIds[key] = a.id as String;
        assets++;
      },
      'asset $key',
    );
  }

  await addAsset(
    key: 'cash',
    accountKey: 'cn_bank',
    type: AssetType.fxAsset,
    code: 'CNY-CASH',
    qty: '120000',
    cost: '1',
    price: '1',
    currency: 'CNY',
  );
  await addAsset(
    key: 'fund',
    accountKey: 'cn_bank',
    type: AssetType.fund,
    code: 'CSI300-ETF',
    qty: '8000',
    cost: '3.82',
    price: '4.15',
    currency: 'CNY',
  );
  await addAsset(
    key: 'aapl',
    accountKey: 'us_broker',
    type: AssetType.stock,
    code: 'AAPL',
    qty: '40',
    cost: '185.20',
    price: '213.80',
    currency: 'USD',
  );
  await addAsset(
    key: 'bond',
    accountKey: 'us_custody',
    type: AssetType.bond,
    code: 'US-TREASURY-10Y',
    qty: '10000',
    cost: '100',
    price: '96.40',
    currency: 'USD',
    typeInfo: FixedIncomeInfo(
      annualRate: Decimal.parse('0.04'),
      startDate: DateTime.utc(2023, 8, 15),
      maturityDate: DateTime.utc(2033, 8, 15),
      compounding: 'annual',
      dayCount: 365,
    ),
  );
  await addAsset(
    key: 'cd',
    accountKey: 'cn_bank',
    type: AssetType.cd,
    code: 'CNY-1Y-CD-2024',
    qty: '50000',
    cost: '1',
    price: '1.032',
    currency: 'CNY',
    typeInfo: FixedIncomeInfo(
      annualRate: Decimal.parse('0.032'),
      startDate: DateTime.utc(2024, 6, 1),
      maturityDate: DateTime.utc(2025, 6, 1),
      compounding: 'simple',
      dayCount: 365,
    ),
  );
  await addAsset(
    key: 'policy',
    accountKey: 'cn_insurance',
    type: AssetType.policy,
    code: 'PA-ENDOW-20Y',
    qty: '500000',
    cost: '60000',
    price: '72500',
    currency: 'CNY',
    typeInfo: InsuranceInfo(
      insurer: '平安人寿',
      policyNumber: 'PA-ENDOW-2024-001',
      annualPremium: Decimal.parse('3000'),
      coverage: Decimal.parse('500000'),
      effectiveDate: DateTime.utc(2024, 1, 1),
      paymentFrequency: 'annual',
    ),
  );
  await addAsset(
    key: 'gold',
    accountKey: 'us_custody',
    type: AssetType.preciousMetal,
    code: 'XAU',
    qty: '8',
    cost: '1900',
    price: '2318',
    currency: 'USD',
    typeInfo: PreciousMetalInfo(
      metalType: 'gold',
      weight: Decimal.parse('8'),
      purity: Decimal.parse('0.9999'),
    ),
  );
  await addAsset(
    key: 'btc',
    accountKey: 'crypto_exchange',
    type: AssetType.crypto,
    code: 'BTC',
    qty: '0.85',
    cost: '46500',
    price: '62800',
    currency: 'USD',
  );
  await addAsset(
    key: 'eth_perp',
    accountKey: 'crypto_exchange',
    type: AssetType.perpetual,
    code: 'ETH-PERP',
    qty: '1',
    cost: '3050',
    price: '3085',
    currency: 'USD',
  );
  await addAsset(
    key: 'private_equity',
    accountKey: 'us_custody',
    type: AssetType.equity,
    code: 'OPENAI-PE',
    qty: '500',
    cost: '25',
    price: '38',
    currency: 'USD',
  );
  await addAsset(
    key: 'tsla_call',
    accountKey: 'sg_broker_inactive',
    type: AssetType.option,
    code: 'TSLA-250620-C300',
    qty: '3',
    cost: '7.20',
    price: '5.30',
    currency: 'USD',
    status: AssetStatus.frozen,
  );
  await addAsset(
    key: 'es_future',
    accountKey: 'sg_broker_inactive',
    type: AssetType.future,
    code: 'ES-DEC25',
    qty: '1',
    cost: '5400',
    price: '5488',
    currency: 'USD',
  );
  await addAsset(
    key: 'hsi_warrant',
    accountKey: 'hk_bank_dormant',
    type: AssetType.warrant,
    code: 'HSI-CALL-W25',
    qty: '10000',
    cost: '0.12',
    price: '0.19',
    currency: 'HKD',
    status: AssetStatus.redeemed,
  );
  await addAsset(
    key: 'oil_contract',
    accountKey: 'eu_bank_closed',
    type: AssetType.contract,
    code: 'BRENT-OTC-2026',
    qty: '2',
    cost: '78',
    price: '74',
    currency: 'USD',
    status: AssetStatus.closed,
  );
  await addAsset(
    key: 'jpy_cash',
    accountKey: 'hk_bank_dormant',
    type: AssetType.fxAsset,
    code: 'JPY-CASH',
    qty: '1500000',
    cost: '1',
    price: '1',
    currency: 'JPY',
  );

  if (ctx.assetIds['aapl'] case final aaplId?) {
    final current = (await deps.assets.findById(aaplId)).valueOrNull;
    if (current != null) {
      final afterAdd = current.copyWith(
        quantity: current.quantity + Decimal.parse('5'),
        costPrice: Decimal.parse('188.10'),
      );
      final r1 = await deps.updateAsset(prev: current, next: afterAdd);
      r1.when(
        ok: (_) => costHistoryPoints++,
        err: (e) => ctx.errors.add('asset update add: ${e.message}'),
      );
      final refreshed = (await deps.assets.findById(aaplId)).valueOrNull;
      if (refreshed != null) {
        final afterTrim = refreshed.copyWith(
          quantity: refreshed.quantity - Decimal.parse('2'),
        );
        final r2 = await deps.updateAsset(prev: refreshed, next: afterTrim);
        r2.when(
          ok: (_) => costHistoryPoints++,
          err: (e) => ctx.errors.add('asset update trim: ${e.message}'),
        );
      }
    }
  }

  if (ctx.accountIds['cn_bank'] case final cnId?) {
    final existing = await deps.cardRepo.findById('base-card');
    if (existing.isErr) {
      final r = await deps.cardRepo.create(
        card: BankCard(
          id: 'base-card',
          accountId: cnId,
          cardOrganization: CardOrganization.visa.code,
          cardNoMasked: '**** **** **** 1111',
          cardType: CardType.credit,
          expireMonth: now.month == 12 ? 1 : now.month + 1,
          expireYear: now.month == 12 ? now.year + 1 : now.year,
          issuerName: '招商银行 Visa 信用卡',
          currency: 'CNY',
          creditLimit: Decimal.parse('80000'),
          availableCredit: Decimal.parse('26500'),
          billingCycleDay: now.day == 1 ? 2 : now.day,
          paymentDueDay: now.day >= 25 ? 28 : now.day + 3,
          billingAddress: '深圳市南山区科技园测试地址 8 号',
          status: CardStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
        plainCardNo: '4111111111111111',
        plainCvv: '123',
      );
      r.when(
        ok: (_) {
          ctx.cardIds['base_card'] = 'base-card';
          cards++;
        },
        err: (e) => ctx.errors.add('base card: ${e.message}'),
      );
    }
  }

  Future<void> linkBuiltinChannel({
    required String key,
    required String channelId,
    required List<String> accountKeys,
  }) async {
    ctx.channelIds[key] = channelId;
    for (final accountKey in accountKeys) {
      final accountId = ctx.accountIds[accountKey];
      if (accountId == null) continue;
      final link = await deps.linkAccountChannel.link(
        accountId: accountId,
        channelId: channelId,
      );
      link.when(
        ok: (_) => channelLinks++,
        err: (e) =>
            ctx.errors.add('channel-link $key/$accountKey: ${e.message}'),
      );
    }
  }

  await linkBuiltinChannel(
    key: 'SWIFT',
    channelId: 'builtin_ch_swift',
    accountKeys: const ['cn_bank', 'us_broker', 'us_custody'],
  );
  await linkBuiltinChannel(
    key: 'CNAPS',
    channelId: 'builtin_ch_cn_cny',
    accountKeys: const ['cn_bank', 'cn_payment'],
  );
  await linkBuiltinChannel(
    key: 'CIPS',
    channelId: 'builtin_ch_cn_cips',
    accountKeys: const ['cn_bank', 'hk_bank_dormant', 'cn_payment'],
  );
  await linkBuiltinChannel(
    key: 'ACH',
    channelId: 'builtin_ch_us_ach',
    accountKeys: const ['us_broker', 'us_custody'],
  );
  await linkBuiltinChannel(
    key: 'FPS',
    channelId: 'builtin_ch_hk_fps',
    accountKeys: const ['cn_payment'],
  );
  await linkBuiltinChannel(
    key: 'CHATS',
    channelId: 'builtin_ch_hk_chats',
    accountKeys: const ['hk_bank_dormant', 'us_broker'],
  );
  await ctx.collect(
    deps.saveChannel(
      Channel(
        id: deps.idGen(),
        name: 'SEPA',
        transferProtocol: 'SEPA',
        limitCurrency: 'EUR',
        dailyLimit: Decimal.parse('200000'),
        singleLimit: Decimal.parse('50000'),
        status: ChannelStatus.enabled,
        createdAt: now,
        updatedAt: now,
      ),
    ),
    (Channel channel) {
      ctx.channelIds['SEPA'] = channel.id;
      channels++;
    },
    'channel SEPA',
  );
  await linkBuiltinChannel(
    key: 'SEPA',
    channelId: ctx.channelIds['SEPA'] ?? 'missing',
    accountKeys: const ['eu_bank_closed', 'us_broker'],
  );

  Future<void> addPair({
    required String base,
    required String quote,
    required List<(int, String, SnapshotType)> series,
    Decimal? high,
    Decimal? low,
    Decimal? pct,
  }) async {
    final added = await deps.manageWatchedPair.add(
      baseCurrency: base,
      quoteCurrency: quote,
    );
    added.when(
      ok: (_) => watchedPairs++,
      err: (e) => ctx.errors.add('watch pair $base/$quote: ${e.message}'),
    );
    final thresholds = await deps.manageWatchedPair.updateThresholds(
      pairKey: '$base/$quote',
      thresholdHigh: high,
      thresholdLow: low,
      alertChangePct: pct,
    );
    if (thresholds.isErr) {
      ctx.errors.add(
        'watch thresholds $base/$quote: ${thresholds.errorOrNull!.message}',
      );
    }
    for (final item in series) {
      final at = item.$3 == SnapshotType.realtime
          ? now
          : DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: item.$1));
      final r = await deps.exchangeRates.upsert(
        ExchangeRate(
          id: deps.idGen(),
          pairKey: '$base/$quote',
          baseCurrency: base,
          quoteCurrency: quote,
          rate: Decimal.parse(item.$2),
          asOfTime: at,
          updatedAt: now,
          source: 'demo',
          snapshotType: item.$3,
        ),
      );
      r.when(
        ok: (_) => rates++,
        err: (e) =>
            ctx.errors.add('rate save $base/$quote ${item.$2}: ${e.message}'),
      );
    }
  }

  await addPair(
    base: 'USD',
    quote: 'CNY',
    series: const [
      (2, '7.18', SnapshotType.daily),
      (1, '7.22', SnapshotType.daily),
      (0, '7.28', SnapshotType.hourly),
      (0, '7.36', SnapshotType.realtime),
    ],
    high: Decimal.parse('7.34'),
    low: Decimal.parse('7.05'),
    pct: Decimal.parse('1.0'),
  );
  await addPair(
    base: 'EUR',
    quote: 'USD',
    series: const [
      (2, '1.07', SnapshotType.daily),
      (1, '1.08', SnapshotType.daily),
      (0, '1.09', SnapshotType.realtime),
    ],
    high: Decimal.parse('1.10'),
  );
  await addPair(
    base: 'GBP',
    quote: 'USD',
    series: const [
      (2, '1.268', SnapshotType.daily),
      (1, '1.254', SnapshotType.hourly),
      (0, '1.238', SnapshotType.realtime),
    ],
    low: Decimal.parse('1.24'),
    pct: Decimal.parse('5'),
  );
  await addPair(
    base: 'HKD',
    quote: 'CNY',
    series: const [
      (2, '0.91', SnapshotType.daily),
      (1, '0.915', SnapshotType.daily),
      (0, '0.92', SnapshotType.realtime),
    ],
  );
  await addPair(
    base: 'HKD',
    quote: 'USD',
    series: const [
      (3, '0.1276', SnapshotType.daily),
      (2, '0.1279', SnapshotType.daily),
      (1, '0.1282', SnapshotType.hourly),
      (0, '0.1281', SnapshotType.realtime),
    ],
  );

  Future<void> addHistory({
    required String assetKey,
    required String currency,
    required List<(int, String, String)> points,
  }) async {
    final assetId = ctx.assetIds[assetKey];
    if (assetId == null) return;
    for (final point in points) {
      final trigger = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: point.$1));
      final history = AssetPriceHistoryPoint(
        id: deps.idGen(),
        assetId: assetId,
        price: Decimal.parse(point.$2),
        marketValue: Decimal.parse(point.$3),
        currency: currency,
        source: 'demo',
        triggerTime: trigger,
        sourceKey: '$assetId:${yyyymmdd(trigger)}:demo',
        rawPayload: jsonEncode({'seed': true, 'assetKey': assetKey}),
        createdAt: now,
      );
      final saved = await deps.priceHistory.record(history);
      saved.when(
        ok: (_) => pricePoints++,
        err: (e) => ctx.errors.add('price history $assetKey: ${e.message}'),
      );
    }
  }

  await addHistory(
    assetKey: 'fund',
    currency: 'CNY',
    points: const [(2, '4.05', '32400'), (1, '4.10', '32800')],
  );
  await addHistory(
    assetKey: 'aapl',
    currency: 'USD',
    points: const [(2, '208.30', '9360'), (1, '211.20', '9504')],
  );
  await addHistory(
    assetKey: 'btc',
    currency: 'USD',
    points: const [(2, '61500', '52275'), (1, '62800', '53380')],
  );
  await addHistory(
    assetKey: 'gold',
    currency: 'USD',
    points: const [(2, '2280', '18240'), (1, '2318', '18544')],
  );

  Future<void> createEvent(DomainEvent event, String label) async {
    final r = await deps.createEvent(event);
    r.when(
      ok: (_) => events++,
      err: (e) => ctx.errors.add('$label: ${e.message}'),
    );
  }

  if (ctx.assetIds['aapl'] case final aaplId?) {
    await createEvent(
      DomainEvent(
        id: deps.idGen(),
        eventType: DomainEventTypes.assetValuationFailed,
        relatedModel: RelatedModel.asset,
        relatedId: aaplId,
        triggerTime: now.subtract(const Duration(hours: 3)),
        priority: EventPriority.high,
        status: EventStatus.triggered,
        handlingStatus: HandlingStatus.failed,
        handler: 'demo-provider',
        handlingNote: jsonEncode({'stage': 'latest', 'error': '模拟 API 失败'}),
        sourceKey:
            '${DomainEventTypes.assetValuationFailed}:$aaplId:${yyyymmdd(now)}:latest',
        ackRequirement: AckRequirement.optional,
        createdAt: now,
        updatedAt: now,
      ),
      'event valuation failed',
    );
  }
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.account,
      relatedId: 'USD/CNY',
      triggerTime: now.subtract(const Duration(minutes: 40)),
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: 'USD/CNY 最新 7.36，突破上沿 7.34',
      sourceKey: '${DomainEventTypes.rateAlert}:USD/CNY:${yyyymmdd(now)}:high',
      refs: const {'pair': 'USD/CNY', 'kind': 'high'},
      ackRequirement: AckRequirement.optional,
      createdAt: now,
      updatedAt: now,
    ),
    'event rate alert high',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.asset,
      relatedId: 'GBP/USD',
      triggerTime: now.subtract(const Duration(hours: 8)),
      priority: EventPriority.high,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handlingNote: 'GBP/USD 跌破下沿 1.24',
      sourceKey: '${DomainEventTypes.rateAlert}:GBP/USD:${yyyymmdd(now)}:low',
      refs: const {'pair': 'GBP/USD', 'kind': 'low'},
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.confirmed,
      ackAt: now.subtract(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
    ),
    'event rate alert low',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.account,
      relatedId: 'EUR/USD',
      triggerTime: now.subtract(const Duration(hours: 1)),
      priority: EventPriority.medium,
      status: EventStatus.closed,
      handlingStatus: HandlingStatus.handled,
      handlingNote: 'EUR/USD 日内波动超过 1.0%',
      sourceKey:
          '${DomainEventTypes.rateAlert}:EUR/USD:${yyyymmdd(now)}:change',
      refs: const {'pair': 'EUR/USD', 'kind': 'change'},
      ackRequirement: AckRequirement.optional,
      ackStatus: AckStatus.dismissed,
      createdAt: now,
      updatedAt: now,
    ),
    'event rate alert change',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: 'CHANNEL_MAINTENANCE',
      relatedModel: RelatedModel.channel,
      relatedId: ctx.channelIds['SEPA'] ?? 'missing',
      triggerTime: now.subtract(const Duration(hours: 4)),
      priority: EventPriority.low,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handlingNote: 'SEPA 通道维护中',
      sourceKey: 'CHANNEL_MAINTENANCE:${yyyymmdd(now)}:demo',
      ackRequirement: AckRequirement.optional,
      createdAt: now,
      updatedAt: now,
    ),
    'event channel maintenance',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: 'ACCOUNT_DORMANT',
      relatedModel: RelatedModel.account,
      relatedId: ctx.accountIds['cn_insurance'] ?? 'missing',
      triggerTime: now.subtract(const Duration(days: 2)),
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.processing,
      handlingNote: '长期未操作，请人工复核',
      sourceKey: 'ACCOUNT_DORMANT:${yyyymmdd(now)}:demo',
      ackRequirement: AckRequirement.required_,
      ackStatus: AckStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
    'event dormant account',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: 'ACCOUNT_CLOSED',
      relatedModel: RelatedModel.account,
      relatedId: ctx.accountIds['eu_bank_closed'] ?? 'missing',
      triggerTime: now.subtract(const Duration(days: 7)),
      priority: EventPriority.critical,
      status: EventStatus.closed,
      handlingStatus: HandlingStatus.handled,
      handlingNote: '账户已销户，仅保留历史记录用于审计',
      sourceKey: 'ACCOUNT_CLOSED:${yyyymmdd(now)}:demo',
      ackRequirement: AckRequirement.notApplicable,
      createdAt: now,
      updatedAt: now,
    ),
    'event closed account',
  );
  await createEvent(
    DomainEvent(
      id: deps.idGen(),
      eventType: 'TRANSFER_CONFIRMED',
      relatedModel: RelatedModel.account,
      relatedId: ctx.accountIds['cn_bank'] ?? 'missing',
      triggerTime: now.subtract(const Duration(hours: 5)),
      priority: EventPriority.low,
      status: EventStatus.resolved,
      handlingStatus: HandlingStatus.handled,
      handlingNote: 'CNAPS 转账已到账',
      refs: {
        'sourceAccount': ctx.accountIds['cn_bank'] ?? 'missing',
        'targetAccount': ctx.accountIds['cn_payment'] ?? 'missing',
        'channel': ctx.channelIds['CNAPS'] ?? 'builtin_ch_cn_cny',
      },
      ackRequirement: AckRequirement.notApplicable,
      createdAt: now,
      updatedAt: now,
    ),
    'event transfer confirmed',
  );

  return SeedResult(
    accounts: accounts,
    assets: assets,
    cards: cards,
    channels: channels,
    channelLinks: channelLinks,
    events: events,
    watchedPairs: watchedPairs,
    rates: rates,
    pricePoints: pricePoints,
    costHistoryPoints: costHistoryPoints,
    errors: const [],
  );
}
