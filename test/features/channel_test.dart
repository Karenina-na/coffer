import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_channel_repository.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_channel_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';
import 'package:gwp/domain/usecases/channel_rule.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/plan_transfer_route.dart';

Channel _ch({
  required String id,
  String? name,
  Decimal? feeRate,
  Decimal? fixedFee,
  Decimal? single,
  Decimal? daily,
  String? ccy,
  Map<String, dynamic>? rule,
  ChannelStatus status = ChannelStatus.enabled,
  DateTime? from,
  DateTime? to,
}) {
  final now = DateTime.utc(2026, 4, 21);
  return Channel(
    id: id,
    name: name ?? id,
    transferProtocol: 'SWIFT',
    feeRate: feeRate,
    fixedFee: fixedFee,
    singleLimit: single,
    dailyLimit: daily,
    limitCurrency: ccy,
    sovereigntyRegionRule: rule,
    status: status,
    effectiveFrom: from,
    effectiveTo: to,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftChannelRepository channels;
  late DriftAccountChannelRepository accountChannels;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    channels = DriftChannelRepository(db.channelDao);
    accountChannels = DriftAccountChannelRepository(db.accountChannelDao);

    final acct = CreateAccountUseCase(
      accounts,
      idGenerator: _seq(prefix: 'acc-'),
      now: DateTime.now,
    );
    // acc-1 (bank, CN), acc-2 (broker, HK), acc-3 (payment, CN)
    await acct(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'CMB',
    );
    await acct(
      accountType: AccountType.broker,
      sovereigntyRegion: 'HK',
      institutionName: 'Futu',
    );
    await acct(
      accountType: AccountType.payment,
      sovereigntyRegion: 'CN',
      institutionName: 'Alipay',
    );
  });

  tearDown(() async => db.close());

  group('ChannelRuleEngine', () {
    const engine = ChannelRuleEngine();
    final ctx = TransferContext(
      amount: Decimal.parse('1000'),
      currency: 'CNY',
      sourceRegion: 'CN',
      targetRegion: 'HK',
      at: DateTime.utc(2026, 4, 21),
    );

    test('DISABLED 通道被拒', () {
      final c = _ch(id: 'x', status: ChannelStatus.disabled);
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code), contains(RuleViolation.channelDisabled));
    });

    test('有效期窗口之外被拒', () {
      final c = _ch(id: 'x', from: DateTime.utc(2027));
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code),
          contains(RuleViolation.channelNotEffective));
    });

    test('currency 不匹配被拒', () {
      final c = _ch(id: 'x', ccy: 'USD');
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code), contains(RuleViolation.currencyMismatch));
    });

    test('single/daily 限额超限', () {
      final c = _ch(
        id: 'x',
        single: Decimal.parse('500'),
        daily: Decimal.parse('800'),
      );
      final v = engine.evaluate(c, ctx);
      final codes = v.map((e) => e.code).toSet();
      expect(codes, contains(RuleViolation.amountExceedsSingleLimit));
      expect(codes, contains(RuleViolation.amountExceedsDailyLimit));
    });

    test('blockedRegions 命中即拒', () {
      final c = _ch(id: 'x', rule: {
        'blockedRegions': ['HK'],
      });
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code), contains(RuleViolation.regionBlocked));
    });

    test('allowedRegions 未覆盖即拒', () {
      final c = _ch(id: 'x', rule: {
        'allowedRegions': ['CN'],
      });
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code), contains(RuleViolation.regionNotAllowed));
    });

    test('requireSameRegion=true 且不一致即拒', () {
      final c = _ch(id: 'x', rule: {'requireSameRegion': true});
      final v = engine.evaluate(c, ctx);
      expect(v.map((e) => e.code), contains(RuleViolation.regionMustMatch));
    });

    test('全部通过时 evaluate 返回空', () {
      final c = _ch(
        id: 'x',
        single: Decimal.parse('10000'),
        daily: Decimal.parse('50000'),
        ccy: 'CNY',
        rule: {
          'allowedRegions': ['CN', 'HK'],
        },
      );
      expect(engine.evaluate(c, ctx), isEmpty);
    });
  });

  group('PlanTransferRouteUseCase', () {
    late PlanTransferRouteUseCase uc;

    setUp(() {
      uc = PlanTransferRouteUseCase(
        accounts,
        channels,
        accountChannels,
        now: () => DateTime.utc(2026, 4, 21),
      );
    });

    Future<void> seedChannel(Channel c, List<String> members) async {
      final r = await channels.upsert(c);
      expect(r.isOk, isTrue);
      for (final accId in members) {
        final lr = await accountChannels.link(
          accountId: accId,
          channelId: c.id,
        );
        expect(lr.isOk, isTrue);
      }
    }

    test('单跳: 两个账户共享同一通道直接互转', () async {
      await seedChannel(
        _ch(
          id: 'ch-direct',
          feeRate: Decimal.parse('0.01'),
          fixedFee: Decimal.parse('1'),
        ),
        ['acc-1', 'acc-2'],
      );
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
      );
      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      expect(route.legs.length, 1);
      expect(route.legs.first.channel.id, 'ch-direct');
      expect(route.legs.first.fromAccount.id, 'acc-1');
      expect(route.legs.first.toAccount.id, 'acc-2');
      expect(route.totalFee, Decimal.parse('11.00'));
      expect(route.isExecutable, isTrue);
    });

    test('多跳: 通过中继账户串联两个通道', () async {
      // acc-1 ↔ acc-3 via ch-bp；acc-3 ↔ acc-2 via ch-pb。
      // acc-1 与 acc-2 无共同通道，须走 acc-3 中转。
      await seedChannel(
        _ch(id: 'ch-bp', feeRate: Decimal.parse('0.002')),
        ['acc-1', 'acc-3'],
      );
      await seedChannel(
        _ch(id: 'ch-pb', feeRate: Decimal.parse('0.003')),
        ['acc-3', 'acc-2'],
      );
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
      );
      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      expect(route.legs.map((l) => l.channel.id).toList(),
          ['ch-bp', 'ch-pb']);
      expect(route.legs.map((l) => l.fromAccount.id).toList(),
          ['acc-1', 'acc-3']);
      expect(route.legs.map((l) => l.toAccount.id).toList(),
          ['acc-3', 'acc-2']);
      // 0.002*1000 + 0.003*1000 = 5
      expect(route.totalFee, Decimal.parse('5.000'));
      expect(route.isExecutable, isTrue);
    });

    test('minFee vs minHops 挑选不同路径', () async {
      // 直连高费率、多跳合计更低
      await seedChannel(
        _ch(id: 'ch-direct-hi', feeRate: Decimal.parse('0.02')),
        ['acc-1', 'acc-2'],
      );
      await seedChannel(
        _ch(id: 'ch-bp', feeRate: Decimal.parse('0.001')),
        ['acc-1', 'acc-3'],
      );
      await seedChannel(
        _ch(id: 'ch-pb', feeRate: Decimal.parse('0.002')),
        ['acc-3', 'acc-2'],
      );
      final rFee = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
        objective: RouteObjective.minFee,
      );
      expect(rFee.valueOrNull!.legs.map((l) => l.channel.id).toList(),
          ['ch-bp', 'ch-pb']);

      final rHops = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
        objective: RouteObjective.minHops,
      );
      expect(rHops.valueOrNull!.legs.map((l) => l.channel.id).toList(),
          ['ch-direct-hi']);
    });

    test('账户级费率覆盖会替代通道默认费率', () async {
      await seedChannel(
        _ch(id: 'ch-direct', feeRate: Decimal.parse('0.02')),
        ['acc-1', 'acc-2'],
      );
      await seedChannel(
        _ch(id: 'ch-bp', feeRate: Decimal.parse('0.0015')),
        ['acc-1', 'acc-3'],
      );
      await seedChannel(
        _ch(id: 'ch-pb', feeRate: Decimal.parse('0.0015')),
        ['acc-3', 'acc-2'],
      );

      final override = await accountChannels.saveConfig(
        accountId: 'acc-1',
        channelId: 'ch-direct',
        feeRateOverride: Decimal.zero,
        fixedFeeOverride: Decimal.zero,
      );
      expect(override.isOk, isTrue);

      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
        objective: RouteObjective.minFee,
      );
      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      expect(route.legs.map((l) => l.channel.id).toList(), ['ch-direct']);
      expect(route.totalFee, Decimal.zero);
    });

    test('无通道可达: NotFoundError', () async {
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('100'),
        currency: 'CNY',
      );
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('通道存在但账户未关联: NotFoundError', () async {
      // 通道存在但 acc-1/acc-2 都没登记 → 图里没有边。
      final r0 = await channels.upsert(_ch(id: 'ch-none'));
      expect(r0.isOk, isTrue);
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('100'),
        currency: 'CNY',
      );
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('所有通道被规则拒绝: 返回不可执行路径 + violations', () async {
      await seedChannel(
        _ch(id: 'ch-blocked', rule: {
          'blockedRegions': ['HK'],
        }),
        ['acc-1', 'acc-2'],
      );
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('100'),
        currency: 'CNY',
      );
      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      expect(route.isExecutable, isFalse);
      expect(route.violations, isNotEmpty);
    });

    test('违规边被跳过，改走合规多跳', () async {
      // 直连违规、多跳合规
      await seedChannel(
        _ch(
          id: 'ch-direct-blocked',
          feeRate: Decimal.parse('0.001'),
          rule: {
            'blockedRegions': ['HK'],
          },
        ),
        ['acc-1', 'acc-2'],
      );
      await seedChannel(
        _ch(id: 'ch-bp', feeRate: Decimal.parse('0.002')),
        ['acc-1', 'acc-3'],
      );
      await seedChannel(
        _ch(id: 'ch-pb', feeRate: Decimal.parse('0.003')),
        ['acc-3', 'acc-2'],
      );
      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('1000'),
        currency: 'CNY',
      );
      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      expect(route.isExecutable, isTrue);
      expect(route.legs.map((l) => l.channel.id).toList(),
          ['ch-bp', 'ch-pb']);
    });

    test('amount ≤ 0 / 同账户 被拦截', () async {
      final r1 = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.zero,
        currency: 'CNY',
      );
      expect(r1.errorOrNull, isA<ValidationError>());

      final r2 = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-1',
        amount: Decimal.one,
        currency: 'CNY',
      );
      expect(r2.errorOrNull, isA<ValidationError>());
    });

    test('手续费 >= 金额 的通道被判定为无效配置', () async {
      await seedChannel(
        _ch(
          id: 'ch-expensive',
          feeRate: Decimal.parse('1.0'),
        ),
        ['acc-1', 'acc-2'],
      );

      final r = await uc(
        sourceAccountId: 'acc-1',
        targetAccountId: 'acc-2',
        amount: Decimal.parse('100'),
        currency: 'CNY',
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
    });

    test('SWIFT收费15时走CIPS换汇CHATS更便宜', () async {
      // ICBC(CN): CIPS, SWIFT
      // HSBC(HK): CIPS, CHATS, SWIFT
      // IBKR(US): CHATS, SWIFT, ACH
      // SWIFT fixedFee=15, others free. All accounts FX enabled.
      // Transfer CNY 20 → USD from ICBC to IBKR.
      final create = CreateAccountUseCase(accounts, idGenerator: _seq(prefix: 'fx-'), now: () => DateTime.utc(2026, 4, 21));
      final icbcR = await create(accountType: AccountType.bank, sovereigntyRegion: 'CN', institutionName: '工商银行', fxSpreadPercent: 0.3);
      final hsbcR = await create(accountType: AccountType.bank, sovereigntyRegion: 'HK', institutionName: '汇丰银行', fxSpreadPercent: 0.3);
      final ibkrR = await create(accountType: AccountType.broker, sovereigntyRegion: 'US', institutionName: 'IBKR', fxSpreadPercent: 0.3);

      final icbc = icbcR.valueOrNull!;
      final hsbc = hsbcR.valueOrNull!;
      final ibkr = ibkrR.valueOrNull!;

      // Create channels (need to use full constructor for protocol)
      final now = DateTime.utc(2026, 4, 21);
      Channel _mk(String id, String name, String proto, {Decimal? fixedFee, String? ccy, Map<String, dynamic>? rule}) => Channel(
        id: id, name: name, transferProtocol: proto, status: ChannelStatus.enabled,
        fixedFee: fixedFee, limitCurrency: ccy, sovereigntyRegionRule: rule,
        createdAt: now, updatedAt: now);
      final cips = _mk('cips', 'CIPS', 'CIPS', ccy: 'CNY', rule: {'allowedRegions': ['CN', 'HK']});
      final chats = _mk('chats', 'CHATS', 'CHATS', ccy: 'USD', rule: {'allowedRegions': ['HK']});
      final swift = _mk('swift', 'SWIFT', 'SWIFT', fixedFee: Decimal.fromInt(15));
      final ach = _mk('ach', 'ACH', 'ACH');

      for (final c in [cips, chats, swift, ach]) {
        await channels.upsert(c);
      }

      // Link accounts
      for (final (acc, ch) in [(icbc, cips), (icbc, swift), (hsbc, cips), (hsbc, chats), (hsbc, swift), (ibkr, chats), (ibkr, swift), (ibkr, ach)]) {
        await accountChannels.link(accountId: acc.id, channelId: ch.id);
      }
      // IBKR on CHATS needs HK region override
      await accountChannels.saveConfig(
        accountId: ibkr.id, channelId: chats.id,
        feeRateOverride: null, fixedFeeOverride: null, feeCurrencyOverride: null,
        regionOverride: 'HK',
      );

      final uc = PlanTransferRouteUseCase(accounts, channels, accountChannels, now: () => DateTime.utc(2026, 4, 21));
      final r = await uc(
        sourceAccountId: icbc.id, targetAccountId: ibkr.id,
        amount: Decimal.fromInt(20), currency: 'CNY', targetCurrency: 'USD',
        fxRates: {'USD/CNY': 7.25, 'CNY/USD': 0.138},
      );

      expect(r.isOk, isTrue);
      final route = r.valueOrNull!;
      // Should be: ICBC→CIPS→HSBC→FX→HSBC(USD)→CHATS→IBKR = 3 hops
      expect(route.legs.length, greaterThan(1));
      // Total fee should be just FX (0.3% of 20 ≈ 0.06), SWIFT 15 would be much worse
      expect(route.totalFee < Decimal.fromInt(10), isTrue, reason: 'should pick cheap CIPS+CHATS path over SWIFT');
      // First hop should use CIPS
      expect(route.legs.first.channel.transferProtocol, equals('CIPS'));
    });
  });
}

String Function() _seq({required String prefix}) {
  var i = 0;
  return () => '$prefix${++i}';
}
