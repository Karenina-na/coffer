import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/data/repositories/drift_event_repository.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/events/event_bus.dart';
import 'package:gwp/domain/usecases/check_asset_sync_outdated.dart';

void main() {
  late AppDatabase db;
  late DriftAssetRepository assetRepo;
  late DriftEventRepository eventRepo;
  late DomainEventBus bus;
  late CheckAssetSyncOutdatedUseCase useCase;

  final now = DateTime.utc(2025, 6, 15, 12);
  var seq = 0;

  setUp(() async {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    assetRepo = DriftAssetRepository(db.assetDao);
    eventRepo = DriftEventRepository(db.eventDao, now: () => now);
    bus = DomainEventBus();
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-1', 'BROKER', 'US', 'IBKR', 'ACTIVE', 1749988800, 1749988800, 0)",
    );
    useCase = CheckAssetSyncOutdatedUseCase(
      assets: assetRepo,
      events: eventRepo,
      bus: bus,
      idGenerator: () => 'evt-${++seq}',
      now: () => now,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  Future<void> seedAsset({
    required String id,
    DateTime? valuationTime,
    bool deleted = false,
  }) async {
    final asset = Asset(
      id: id,
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.fromInt(1),
      currency: 'USD',
      valuationTime: valuationTime,
      status: AssetStatus.holding,
      createdAt: now,
      updatedAt: now,
      isDeleted: deleted,
    );
    final r = await assetRepo.create(asset);
    expect(r.isOk, isTrue, reason: 'seed $id failed: ${r.errorOrNull?.message}');
  }

  test('所有资产均在阈值内则不写事件', () async {
    await seedAsset(
      id: 'a1',
      valuationTime: now.subtract(const Duration(hours: 2)),
    );
    final r = await useCase();
    expect(r.valueOrNull, 0);
    final events = await eventRepo.watchRecent().first;
    expect(events, isEmpty);
  });

  test('资产 valuationTime 过期则写一条聚合事件', () async {
    await seedAsset(
      id: 'a1',
      valuationTime: now.subtract(const Duration(days: 5)),
    );
    await seedAsset(id: 'a2', valuationTime: null);
    await seedAsset(
      id: 'a3',
      valuationTime: now.subtract(const Duration(hours: 1)),
    );
    final r = await useCase();
    expect(r.valueOrNull, 2); // a1 + a2，a3 在阈值内
    final events = await eventRepo.watchRecent().first;
    expect(events, hasLength(1));
    expect(events.single.eventType, 'ASSET_SYNC_OUTDATED');
  });

  test('软删资产被忽略', () async {
    await seedAsset(id: 'a1', valuationTime: null, deleted: true);
    final r = await useCase();
    expect(r.valueOrNull, 0);
  });

  test('同日重复调用幂等（只保留一条事件）', () async {
    await seedAsset(id: 'a1', valuationTime: null);
    await useCase();
    await useCase();
    final events = await eventRepo.watchRecent().first;
    expect(events, hasLength(1));
  });

  test('relatedId 排序后取最小 assetId（幂等，Bug 17）', () async {
    // 插入多个过期资产，ID 顺序不同
    await seedAsset(id: 'z-asset', valuationTime: null);
    await seedAsset(id: 'a-asset', valuationTime: null);
    await seedAsset(id: 'm-asset', valuationTime: null);

    final r = await useCase();
    expect(r.isOk, isTrue);

    final events = await eventRepo.watchRecent().first;
    expect(events, hasLength(1));
    // relatedId 应指向字典序最小的 assetId
    expect(events.single.relatedId, 'a-asset');
  });

  test('thresholdDays 参数有效（1 天阈值）', () async {
    final customUseCase = CheckAssetSyncOutdatedUseCase(
      assets: assetRepo,
      events: eventRepo,
      bus: bus,
      idGenerator: () => 'evt-custom-${++seq}',
      now: () => now,
      thresholdDays: const Duration(days: 1),
    );

    // 25 hours ago — beyond 1-day threshold
    await seedAsset(
      id: 'b1',
      valuationTime: now.subtract(const Duration(hours: 25)),
    );
    // 30 minutes ago — within 1-day threshold
    await seedAsset(
      id: 'b2',
      valuationTime: now.subtract(const Duration(minutes: 30)),
    );

    final r = await customUseCase();
    expect(r.valueOrNull, 1); // only b1 is outdated
  });

  test('所有资产均在阈值内时不写事件', () async {
    await seedAsset(
      id: 'c1',
      valuationTime: now.subtract(const Duration(hours: 1)),
    );
    await seedAsset(
      id: 'c2',
      valuationTime: now.subtract(const Duration(hours: 2)),
    );

    final r = await useCase();
    expect(r.valueOrNull, 0);
    final events = await eventRepo.watchRecent().first;
    expect(events, isEmpty);
  });
}
