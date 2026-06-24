import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_asset_cost_history_repository.dart';
import 'package:coffer/domain/entities/asset_cost_history_point.dart';

void main() {
  late AppDatabase db;
  late DriftAssetCostHistoryRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftAssetCostHistoryRepository(db.assetCostHistoryDao);
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-1', 'BROKER', 'US', 'IBKR', 'ACTIVE', 1735725600, 1735725600, 0)",
    );
    await db.customStatement(
      "INSERT INTO assets "
      "(id, account_id, asset_type, quantity, currency, status, created_at, updated_at, is_deleted) "
      "VALUES ('a1', 'acc-1', 'STOCK', '10', 'USD', 'HOLDING', 1735725600, 1735725600, 0)",
    );
  });

  tearDown(() => db.close());

  AssetCostHistoryPoint mk({
    String id = 'c1',
    String assetId = 'a1',
    String? costPrice = '100.5',
    String quantity = '10',
    String? reason,
    String? sourceKey,
    DateTime? at,
  }) {
    final t = at ?? DateTime.utc(2025, 1, 1, 10);
    return AssetCostHistoryPoint(
      id: id,
      assetId: assetId,
      costPrice: costPrice == null ? null : Decimal.parse(costPrice),
      quantity: Decimal.parse(quantity),
      currency: 'USD',
      source: 'manual',
      reason: reason,
      triggerTime: t,
      sourceKey: sourceKey,
      createdAt: t,
    );
  }

  test('record inserts a row and can be listed by asset', () async {
    final r = await repo.record(mk());
    expect(r.isOk, true);
    final list = await repo.listByAsset('a1');
    expect(list.length, 1);
    expect(list.first.costPrice, Decimal.parse('100.5'));
    expect(list.first.quantity, Decimal.parse('10'));
  });

  test('record is idempotent on sourceKey', () async {
    final now = DateTime.utc(2025, 1, 1, 10);
    await repo.record(mk(id: 'c1', sourceKey: 'a1:${now.toIso8601String()}', at: now));
    await repo.record(mk(id: 'c2', sourceKey: 'a1:${now.toIso8601String()}', at: now));
    final list = await repo.listByAsset('a1');
    expect(list.length, 1);
    expect(list.first.id, 'c1');
  });

  test('list is ordered by triggerTime desc (latest first)', () async {
    await repo.record(mk(id: 'c1', at: DateTime.utc(2025, 1, 1)));
    await repo.record(mk(id: 'c2', at: DateTime.utc(2025, 1, 3)));
    await repo.record(mk(id: 'c3', at: DateTime.utc(2025, 1, 2)));
    final list = await repo.listByAsset('a1');
    expect(list.map((e) => e.id).toList(), ['c2', 'c3', 'c1']);
  });

  test('latestForAsset returns the most recent record', () async {
    await repo.record(mk(id: 'c1', at: DateTime.utc(2025, 1, 1)));
    await repo.record(mk(id: 'c2', at: DateTime.utc(2025, 1, 5)));
    final latest = await repo.latestForAsset('a1');
    expect(latest?.id, 'c2');
  });
}
