/// E2E 3: 备份/恢复完整往返
///
/// 播种多表数据 → 导出（验证快照含全部表） → 清空 DB → 导入 → 逐表断言 →
/// 错误密码被拒 → AAD 篡改被拒
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/crypto/password_kdf.dart';
import 'package:gwp/data/backup/db_snapshot.dart';
import 'package:gwp/data/crypto_service.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/exchange_rate.dart';
import 'package:gwp/domain/entities/exchange_rate_enums.dart';
import 'package:gwp/domain/usecases/backup_restore.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/utils/pair_key.dart';

void main() {
  late AppDatabase db;
  late DbSnapshotService snapshot;
  late CryptoService crypto;

  final fastKdf = PasswordKdf(memoryKib: 4096, iterations: 2, parallelism: 1);
  final now = DateTime.utc(2025, 6, 15);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    crypto = CryptoService();
    snapshot = DbSnapshotService(db, crypto);

    // Seed account
    final accountRepo = DriftAccountRepository(db.accountDao);
    final createAccount = CreateAccountUseCase(
      accountRepo,
      idGenerator: () => 'acc-1',
      now: () => now,
    );
    final r = await createAccount(
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'IBKR',
    );
    expect(r.isOk, isTrue);
  });

  tearDown(() => db.close());

  test('完整往返：多表数据导出后恢复', () async {
    // Seed asset
    final assetRepo = DriftAssetRepository(db.assetDao);
    final asset = Asset(
      id: 'ast-1',
      accountId: 'acc-1',
      assetType: AssetType.stock,
      assetCode: 'AAPL',
      quantity: Decimal.fromInt(100),
      currency: 'USD',
      status: AssetStatus.holding,
      createdAt: now,
      updatedAt: now,
    );
    final assetResult = await assetRepo.create(asset);
    expect(assetResult.isOk, isTrue);

    // Seed exchange rate
    final rateRepo = DriftExchangeRateRepository(db.exchangeRateDao);
    await rateRepo.upsert(ExchangeRate(
      id: 'er-1',
      pairKey: pairKeyOf('USD', 'CNY'),
      baseCurrency: 'USD',
      quoteCurrency: 'CNY',
      rate: Decimal.parse('7.2'),
      asOfTime: now,
      updatedAt: now,
      source: 'test',
      snapshotType: SnapshotType.daily,
    ));

    // Seed watched pair
    await db.customStatement(
      "INSERT INTO watched_pairs "
      "(pair_key, base_currency, quote_currency, created_at) "
      "VALUES ('USD/CNY', 'USD', 'CNY', 1749988800)",
    );

    // Export
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'e2e-pass-test');
    expect(packed.isOk, isTrue);

    // Verify snapshot contains all required tables
    final snap = await snapshot.export();
    for (final table in [
      'accounts',
      'assets',
      'asset_cost_history',
      'exchange_rates',
      'watched_pairs',
      'events',
      'asset_price_history',
      'account_channels',
      'channels',
      'cards',
      'search_history_entries',
      'dict_entries',
    ]) {
      expect(snap.containsKey(table), isTrue, reason: 'Table $table missing from snapshot');
    }

    // Clear all tables
    await db.delete(db.watchedPairs).go();
    await db.delete(db.exchangeRates).go();
    await db.delete(db.assets).go();
    await db.delete(db.accounts).go();

    expect(await db.select(db.accounts).get(), isEmpty);
    expect(await db.select(db.assets).get(), isEmpty);

    // Import
    final importer = ImportBackupUseCase(snapshot);
    final restored = await importer(
      package: packed.valueOrNull!,
      password: 'e2e-pass-test',
    );
    expect(restored.isOk, isTrue);

    // Verify restoration
    final accounts = await db.select(db.accounts).get();
    expect(accounts.length, 1);
    expect(accounts.single.id, 'acc-1');

    final assets = await db.select(db.assets).get();
    expect(assets.length, 1);
    expect(assets.single.id, 'ast-1');

    final rates = await db.select(db.exchangeRates).get();
    expect(rates.length, 1);
    expect(rates.single.id, 'er-1');

    final pairs = await db.select(db.watchedPairs).get();
    expect(pairs.length, 1);
    expect(pairs.single.pairKey, 'USD/CNY');
  });

  test('错误密码解密失败', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'correct-pass-123');
    expect(packed.isOk, isTrue);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: packed.valueOrNull!, password: 'wrong-pass-123');
    expect(r.isErr, isTrue);
  });

  test('AAD 篡改（kdf.params.t 修改）被拒绝', () async {
    final exporter = ExportBackupUseCase(snapshot, kdf: fastKdf);
    final packed = await exporter(password: 'valid-pass-aad');
    expect(packed.isOk, isTrue);

    // Tamper with kdf.params.t to simulate downgrade attack
    final pack = jsonDecode(packed.valueOrNull!) as Map<String, dynamic>;
    (pack['kdf']['params'] as Map)['t'] = 1;
    final tampered = jsonEncode(pack);

    final importer = ImportBackupUseCase(snapshot);
    final r = await importer(package: tampered, password: 'valid-pass-aad');
    expect(r.isErr, isTrue, reason: 'Tampered AAD must cause decryption failure');
  });
}
