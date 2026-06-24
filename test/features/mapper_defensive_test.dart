import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/daos/asset_mapper.dart';
import 'package:coffer/data/db/daos/asset_price_history_mapper.dart';
import 'package:coffer/data/db/daos/exchange_rate_mapper.dart';
import 'package:coffer/data/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('Mapper 兜底：数值列异常不触发 crash', () {
    test('AssetMapper 空 quantity 回退到 0', () async {
      await db.customStatement(
        "INSERT INTO accounts "
        "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
        "VALUES ('acc', 'BANK', 'CN', 'CMB', 'ACTIVE', 1704067200, 1704067200, 0)",
      );

      // 直接低层插入一条 quantity 为空串的行，模拟历史迁移残留。
      await db.into(db.assets).insert(AssetsCompanion.insert(
            id: 'a-bad',
            accountId: 'acc',
            assetType: 'FX_ASSET',
            quantity: '', // ← 异常数据
            currency: 'CNY',
            status: 'HOLDING',
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
          ));

      final row = await (db.select(db.assets)
            ..where((t) => t.id.equals('a-bad')))
          .getSingle();

      const mapper = AssetMapper();
      // 关键：不再抛异常
      final asset = mapper.toDomain(row);
      expect(asset.quantity, Decimal.zero);
    });

    test('ExchangeRateMapper 空 rate 回退到 0', () async {
      await db.into(db.exchangeRates).insert(ExchangeRatesCompanion.insert(
            id: 'er-bad',
            pairKey: 'USD-CNY',
            baseCurrency: 'USD',
            quoteCurrency: 'CNY',
            rate: '',
            asOfTime: DateTime.utc(2024, 1, 1),
            updatedAt: DateTime.utc(2024, 1, 1),
            source: 'manual',
            snapshotType: 'DAILY',
          ));
      final row = await (db.select(db.exchangeRates)
            ..where((t) => t.id.equals('er-bad')))
          .getSingle();
      const mapper = ExchangeRateMapper();
      final er = mapper.toDomain(row);
      expect(er.rate, Decimal.zero);
    });

    test('AssetPriceHistoryMapper 非法 price 回退到 0，marketValue 容忍 null', () async {
      await db.customStatement(
        "INSERT INTO accounts "
        "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
        "VALUES ('acc-aph', 'BROKER', 'CN', 'Legacy Broker', 'ACTIVE', 1704067200, 1704067200, 0)",
      );
      await db.customStatement(
        "INSERT INTO assets "
        "(id, account_id, asset_type, quantity, currency, status, created_at, updated_at, is_deleted) "
        "VALUES ('a', 'acc-aph', 'FX_ASSET', '1', 'CNY', 'HOLDING', 1704067200, 1704067200, 0)",
      );

      await db.into(db.assetPriceHistory).insert(
            AssetPriceHistoryCompanion.insert(
              id: 'aph-bad',
              assetId: 'a',
              price: 'not-a-number',
              currency: 'CNY',
              source: 'manual',
              triggerTime: DateTime.utc(2024),
              createdAt: DateTime.utc(2024),
            ),
          );
      final row = await (db.select(db.assetPriceHistory)
            ..where((t) => t.id.equals('aph-bad')))
          .getSingle();
      const mapper = AssetPriceHistoryMapper();
      final p = mapper.toDomain(row);
      expect(p.price, Decimal.zero);
      expect(p.marketValue, equals(null));
    });
  });
}
