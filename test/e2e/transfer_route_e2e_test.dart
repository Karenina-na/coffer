/// E2E 4: 多跳转账路径规划
///
/// 4 账户 3 渠道复杂图 → minFee 目标 → 验证全部边重建 →
/// minHops 目标 → 无效渠道排除 → 不可达 / 自环错误处理
library;

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
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/plan_transfer_route.dart';

Channel _ch({
  required String id,
  Decimal? feeRate,
  Decimal? fixedFee,
  Map<String, dynamic>? rule,
  ChannelStatus status = ChannelStatus.enabled,
}) {
  final now = DateTime.utc(2025, 6, 15);
  return Channel(
    id: id,
    name: id,
    transferProtocol: 'TEST',
    feeRate: feeRate,
    fixedFee: fixedFee,
    sovereigntyRegionRule: rule,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftChannelRepository channelRepo;
  late DriftAccountChannelRepository accountChannelRepo;
  late PlanTransferRouteUseCase useCase;

  final now = DateTime.utc(2025, 6, 15);
  var accSeq = 0;

  setUp(() async {
    accSeq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = DriftAccountRepository(db.accountDao);
    channelRepo = DriftChannelRepository(db.channelDao, now: () => now);
    accountChannelRepo = DriftAccountChannelRepository(db.accountChannelDao);

    useCase = PlanTransferRouteUseCase(
      accountRepo,
      channelRepo,
      accountChannelRepo,
      now: () => now,
    );

    // 创建 4 个账户
    final createAccount = CreateAccountUseCase(
      accountRepo,
      idGenerator: () => 'acc-${++accSeq}',
      now: () => now,
    );
    for (var i = 0; i < 4; i++) {
      final r = await createAccount(
        accountType: AccountType.broker,
        sovereigntyRegion: 'US',
        institutionName: 'Bank${i + 1}',
      );
      expect(r.isOk, isTrue);
    }
    // IDs: acc-1, acc-2, acc-3, acc-4
  });

  tearDown(() => db.close());

  Future<void> seedChannel(Channel ch, List<String> accountIds) async {
    await channelRepo.upsert(ch);
    for (final accId in accountIds) {
      await accountChannelRepo.link(accountId: accId, channelId: ch.id);
    }
  }

  test('minFee 目标选择总手续费最低的多跳路径', () async {
    // Topology:
    //   acc-1 → acc-3 via ch-a (fee 0.001)
    //   acc-3 → acc-2 via ch-b (fee 0.002)
    //   acc-1 → acc-2 directly via ch-c (fee 0.01, higher)
    await seedChannel(_ch(id: 'ch-a', feeRate: Decimal.parse('0.001')), ['acc-1', 'acc-3']);
    await seedChannel(_ch(id: 'ch-b', feeRate: Decimal.parse('0.002')), ['acc-3', 'acc-2']);
    await seedChannel(_ch(id: 'ch-c', feeRate: Decimal.parse('0.01')), ['acc-1', 'acc-2']);

    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-2',
      amount: Decimal.parse('1000'),
      currency: 'USD',
      objective: RouteObjective.minFee,
    );
    expect(r.isOk, isTrue);
    final route = r.valueOrNull!;
    expect(route.isExecutable, isTrue);
    expect(route.legs.length, 2);
    expect(route.legs.map((l) => l.channel.id).toList(), ['ch-a', 'ch-b']);
    // Total fee: 1000 * 0.001 + 1000 * 0.002 = 3
    expect(route.totalFee, Decimal.parse('3.000'));
  });

  test('minHops 目标选择跳数最少的直连路径', () async {
    await seedChannel(_ch(id: 'ch-a', feeRate: Decimal.parse('0.001')), ['acc-1', 'acc-3']);
    await seedChannel(_ch(id: 'ch-b', feeRate: Decimal.parse('0.002')), ['acc-3', 'acc-2']);
    await seedChannel(_ch(id: 'ch-c', feeRate: Decimal.parse('0.01')), ['acc-1', 'acc-2']);

    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-2',
      amount: Decimal.parse('1000'),
      currency: 'USD',
      objective: RouteObjective.minHops,
    );
    expect(r.isOk, isTrue);
    final route = r.valueOrNull!;
    expect(route.isExecutable, isTrue);
    expect(route.legs.length, 1);
    expect(route.legs.single.channel.id, 'ch-c');
  });

  test('4 账户复杂图：acc-1→acc-4 通过 acc-2 和 acc-3 中转', () async {
    // acc-1 ↔ acc-2 via ch-12
    // acc-2 ↔ acc-3 via ch-23
    // acc-3 ↔ acc-4 via ch-34
    // No direct path from acc-1 to acc-4
    await seedChannel(_ch(id: 'ch-12', feeRate: Decimal.parse('0.001')), ['acc-1', 'acc-2']);
    await seedChannel(_ch(id: 'ch-23', feeRate: Decimal.parse('0.001')), ['acc-2', 'acc-3']);
    await seedChannel(_ch(id: 'ch-34', feeRate: Decimal.parse('0.001')), ['acc-3', 'acc-4']);

    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-4',
      amount: Decimal.parse('500'),
      currency: 'USD',
    );
    expect(r.isOk, isTrue);
    final route = r.valueOrNull!;
    expect(route.isExecutable, isTrue);
    expect(route.legs.length, 3);
    expect(route.legs.map((l) => l.fromAccount.id).toList(), ['acc-1', 'acc-2', 'acc-3']);
    expect(route.legs.map((l) => l.toAccount.id).toList(), ['acc-2', 'acc-3', 'acc-4']);
  });

  test('无通道可达返回 NotFoundError', () async {
    // No channels seeded
    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-2',
      amount: Decimal.parse('100'),
      currency: 'USD',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('自环（源 == 目标）返回 ValidationError', () async {
    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-1',
      amount: Decimal.parse('100'),
      currency: 'USD',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('DISABLED 渠道被排除，改走合规路径', () async {
    // Direct but disabled
    await seedChannel(
      _ch(id: 'ch-disabled', feeRate: Decimal.parse('0.001'), status: ChannelStatus.disabled),
      ['acc-1', 'acc-2'],
    );
    // Indirect but enabled
    await seedChannel(_ch(id: 'ch-a', feeRate: Decimal.parse('0.005')), ['acc-1', 'acc-3']);
    await seedChannel(_ch(id: 'ch-b', feeRate: Decimal.parse('0.005')), ['acc-3', 'acc-2']);

    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-2',
      amount: Decimal.parse('100'),
      currency: 'USD',
    );
    expect(r.isOk, isTrue);
    final route = r.valueOrNull!;
    expect(route.isExecutable, isTrue);
    // Should use the 2-hop path, not the disabled direct
    expect(route.legs.map((l) => l.channel.id).toList(), containsAll(['ch-a', 'ch-b']));
  });

  test('不可达目标不会返回指向第三方账户的阻断 fallback', () async {
    final blockedRule = {
      'requireSameRegion': true,
    };
    // acc-1 和 acc-3 可见，但规则阻断；acc-2 完全不可达。
    await seedChannel(_ch(id: 'ch-blocked', rule: blockedRule), ['acc-1', 'acc-3']);

    // 把 acc-3 改成不同 region，使 1 -> 3 被规则拒绝。
    await db.customStatement(
      "UPDATE accounts SET sovereignty_region = 'SG' WHERE id = 'acc-3'",
    );

    final r = await useCase(
      sourceAccountId: 'acc-1',
      targetAccountId: 'acc-2',
      amount: Decimal.parse('100'),
      currency: 'USD',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });
}
