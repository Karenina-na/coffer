import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_asset_cost_history_repository.dart';
import 'package:coffer/data/repositories/drift_asset_repository.dart';
import 'package:coffer/domain/entities/asset.dart';
import 'package:coffer/domain/entities/asset_enums.dart';
import 'package:coffer/domain/usecases/update_asset.dart';

void main() {
  late AppDatabase db;
  late UpdateAssetUseCase usecase;
  late DriftAssetRepository assetRepo;
  late DriftAssetCostHistoryRepository costRepo;
  int idSeq = 0;

  Future<Asset> seedAsset({
    Decimal? costPrice,
    Decimal? quantity,
  }) async {
    final now = DateTime.utc(2025, 1, 1);
    final a = Asset(
      id: 'ast1',
      accountId: 'acc1',
      assetType: AssetType.stock,
      quantity: quantity ?? Decimal.parse('10'),
      costPrice: costPrice ?? Decimal.parse('100'),
      currency: 'USD',
      status: AssetStatus.holding,
      createdAt: now,
      updatedAt: now,
    );
    final r = await assetRepo.create(a);
    return r.valueOrNull!;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    assetRepo = DriftAssetRepository(db.assetDao);
    costRepo = DriftAssetCostHistoryRepository(db.assetCostHistoryDao);
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc1', 'BROKER', 'US', 'IBKR', 'ACTIVE', 1735689600, 1735689600, 0)",
    );
    idSeq = 0;
    usecase = UpdateAssetUseCase(
      assetRepo,
      costRepo,
      idGenerator: () => 'id-${++idSeq}',
      now: () => DateTime.utc(2025, 1, 2),
    );
  });

  tearDown(() => db.close());

  test('cost_price 变化时追加一条成本历史', () async {
    final prev = await seedAsset();
    final next = prev.copyWith(costPrice: Decimal.parse('120'));
    final r = await usecase(prev: prev, next: next);
    expect(r.isOk, true);
    final history = await costRepo.listByAsset(prev.id);
    expect(history.length, 1);
    expect(history.first.costPrice, Decimal.parse('120'));
    expect(history.first.source, 'manual');
  });

  test('quantity 变化时也追加一条成本历史', () async {
    final prev = await seedAsset();
    final next = prev.copyWith(quantity: Decimal.parse('15'));
    await usecase(prev: prev, next: next);
    final history = await costRepo.listByAsset(prev.id);
    expect(history.length, 1);
    expect(history.first.quantity, Decimal.parse('15'));
  });

  test('cost_price 与 quantity 均未变时不写审计', () async {
    final prev = await seedAsset();
    final next = prev.copyWith(assetCode: 'AAPL');
    await usecase(prev: prev, next: next);
    final history = await costRepo.listByAsset(prev.id);
    expect(history, isEmpty);
  });
}
