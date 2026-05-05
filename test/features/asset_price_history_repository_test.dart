import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_asset_price_history_repository.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/asset_price_history_point.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/create_asset.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftAssetRepository assets;
  late DriftAssetPriceHistoryRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    assets = DriftAssetRepository(db.assetDao);
    repo = DriftAssetPriceHistoryRepository(db.assetPriceHistoryDao);

    await CreateAccountUseCase(
      accounts,
      idGenerator: () => 'acc-1',
      now: DateTime.now,
    )(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );

    final createAsset = CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'asset-a',
      now: DateTime.now,
    );
    await createAsset(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.one,
      currency: 'USD',
    );
    await CreateAssetUseCase(
      assets,
      accounts,
      idGenerator: () => 'asset-b',
      now: DateTime.now,
    )(
      accountId: 'acc-1',
      assetType: AssetType.stock,
      quantity: Decimal.one,
      currency: 'USD',
    );
  });

  tearDown(() async {
    await db.close();
  });

  AssetPriceHistoryPoint point({
    required String id,
    required String assetId,
    required String marketValue,
    required DateTime triggerTime,
  }) {
    return AssetPriceHistoryPoint(
      id: id,
      assetId: assetId,
      price: Decimal.parse('10'),
      marketValue: Decimal.parse(marketValue),
      currency: 'USD',
      source: 'test',
      triggerTime: triggerTime,
      createdAt: triggerTime,
    );
  }

  test('listForTrend 按时间升序返回并支持 assetIds 过滤', () async {
    await repo.record(
      point(
        id: 'p3',
        assetId: 'asset-b',
        marketValue: '30',
        triggerTime: DateTime.utc(2026, 1, 3),
      ),
    );
    await repo.record(
      point(
        id: 'p1',
        assetId: 'asset-a',
        marketValue: '10',
        triggerTime: DateTime.utc(2026, 1, 1),
      ),
    );
    await repo.record(
      point(
        id: 'p2',
        assetId: 'asset-a',
        marketValue: '20',
        triggerTime: DateTime.utc(2026, 1, 2),
      ),
    );

    final filtered = await repo.listForTrend(assetIds: {'asset-a'});

    expect(filtered.map((e) => e.id).toList(), ['p1', 'p2']);
  });

  test('listForTrend 支持 since 下界过滤', () async {
    await repo.record(
      point(
        id: 'p1',
        assetId: 'asset-a',
        marketValue: '10',
        triggerTime: DateTime.utc(2026, 1, 1),
      ),
    );
    await repo.record(
      point(
        id: 'p2',
        assetId: 'asset-a',
        marketValue: '20',
        triggerTime: DateTime.utc(2026, 1, 2),
      ),
    );

    final filtered = await repo.listForTrend(
      since: DateTime.utc(2026, 1, 2),
    );

    expect(filtered.map((e) => e.id).toList(), ['p2']);
  });
}
