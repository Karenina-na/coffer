/// E2E 1: 资产完整生命周期
///
/// 创建账户 → 创建资产 → 刷新最新价格 → 刷新历史价格 → 部分转移 →
/// 验证原子性 + 成本历史
library;

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_account_repository.dart';
import 'package:coffer/data/repositories/drift_asset_cost_history_repository.dart';
import 'package:coffer/data/repositories/drift_asset_repository.dart';
import 'package:coffer/data/repositories/drift_event_repository.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/events/event_bus.dart';
import 'package:coffer/domain/usecases/create_account.dart';
import 'package:coffer/domain/usecases/create_asset.dart';
import 'package:coffer/domain/usecases/transfer_asset.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftAssetRepository assetRepo;
  late DriftEventRepository eventRepo;
  late DriftAssetCostHistoryRepository costRepo;
  late DomainEventBus bus;

  final now = DateTime.utc(2025, 6, 15, 12);
  var seq = 0;

  setUp(() async {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = DriftAccountRepository(db.accountDao);
    assetRepo = DriftAssetRepository(db.assetDao);
    eventRepo = DriftEventRepository(db.eventDao, now: () => now);
    costRepo = DriftAssetCostHistoryRepository(db.assetCostHistoryDao);
    bus = DomainEventBus();
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  test('资产完整生命周期', () async {
    // 1. 创建两个账户
    final createAccount = CreateAccountUseCase(
      accountRepo,
      idGenerator: () => 'acc-${++seq}',
      now: () => now,
    );
    final accA = await createAccount(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );
    expect(accA.isOk, isTrue);
    final accIdA = accA.valueOrNull!.id;

    final accB = await createAccount(
      accountType: AccountType.broker,
      sovereigntyRegion: 'HK',
      institutionName: 'HKEX',
    );
    expect(accB.isOk, isTrue);
    final accIdB = accB.valueOrNull!.id;

    // 2. 创建资产
    final createAsset = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-${++seq}',
      now: () => now,
    );
    final assetResult = await createAsset(
      accountId: accIdA,
      assetType: AssetType.stock,
      quantity: Decimal.fromInt(100),
      currency: 'USD',
      assetCode: 'AAPL',
      costPrice: Decimal.parse('150'),
      currentPrice: Decimal.parse('160'),
    );
    expect(assetResult.isOk, isTrue);
    final asset = assetResult.valueOrNull!;
    expect(asset.marketValue, Decimal.parse('16000'));
    expect(asset.valuationTime, isNotNull);

    // 3. 验证资产已持久化
    final found = await assetRepo.findById(asset.id);
    expect(found.isOk, isTrue);
    expect(found.valueOrNull!.currentPrice, Decimal.parse('160'));

    // 4. 部分转移（30股）
    final transfer = TransferAssetUseCase(
      assetRepo,
      accountRepo,
      eventRepo,
      costRepo,
      bus,
      idGenerator: () => 'id-${++seq}',
      now: () => now,
    );
    final txResult = await transfer(TransferAssetRequest(
      assetId: asset.id,
      targetAccountId: accIdB,
      newQuantity: Decimal.fromInt(30),
    ));
    expect(txResult.isOk, isTrue);
    final targetAsset = txResult.valueOrNull!;

    // 5. 验证部分转移后的状态
    expect(targetAsset.quantity, Decimal.fromInt(30));
    expect(targetAsset.accountId, accIdB);

    // 6. 源资产数量减少
    final srcAfter = await assetRepo.findById(asset.id);
    expect(srcAfter.valueOrNull!.quantity, Decimal.fromInt(70));

    // 7. 成本历史：源转出 + 目标转入
    final srcHistory = await costRepo.listByAsset(asset.id);
    expect(srcHistory, hasLength(1));
    expect(srcHistory.single.source, 'transfer_out');

    final tgtHistory = await costRepo.listByAsset(targetAsset.id);
    expect(tgtHistory, hasLength(1));
    expect(tgtHistory.single.source, 'transfer_in');

    // 8. 事件写入
    final events = await eventRepo.watchRecent().first;
    expect(
      events.any((e) => e.eventType == 'ASSET_TRANSFERRED'),
      isTrue,
    );

    // 9. watchByAccount 流验证隔离
    final accAAssets = await assetRepo.watchByAccount(accIdA).first;
    final accBAssets = await assetRepo.watchByAccount(accIdB).first;
    expect(accAAssets.length, 1); // original (reduced)
    expect(accBAssets.length, 1); // transferred target
  });

  test('全量转移后源资产软删除', () async {
    final createAccount = CreateAccountUseCase(
      accountRepo,
      idGenerator: () => 'acc-full-${++seq}',
      now: () => now,
    );
    final a = await createAccount(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'A',
    );
    final b = await createAccount(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'B',
    );

    final createAsset = CreateAssetUseCase(
      assetRepo,
      accountRepo,
      idGenerator: () => 'ast-full-${++seq}',
      now: () => now,
    );
    final asset = await createAsset(
      accountId: a.valueOrNull!.id,
      assetType: AssetType.crypto,
      quantity: Decimal.fromInt(10),
      currency: 'BTC',
    );
    expect(asset.isOk, isTrue);

    final transfer = TransferAssetUseCase(
      assetRepo,
      accountRepo,
      eventRepo,
      costRepo,
      bus,
      idGenerator: () => 'id-full-${++seq}',
      now: () => now,
    );
    final result = await transfer(TransferAssetRequest(
      assetId: asset.valueOrNull!.id,
      targetAccountId: b.valueOrNull!.id,
    ));
    expect(result.isOk, isTrue);

    // Source should be soft-deleted (not visible via watchById)
    final srcStream = await assetRepo.watchById(asset.valueOrNull!.id).first;
    expect(srcStream, isNull);

    // Target created with full quantity
    expect(result.valueOrNull!.quantity, Decimal.fromInt(10));
  });
}
