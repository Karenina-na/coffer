import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/auth/pin_store.dart';
import 'package:gwp/core/crypto/password_kdf.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/backup/db_snapshot.dart';
import 'package:gwp/data/crypto_service.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/domain/usecases/reset_all_data.dart';

/// 会在 reset 中被清空的业务表。
const _clearedTables = <String>[
  'accounts',
  'account_channels',
  'assets',
  'asset_cost_history',
  'asset_price_history',
  'cards',
  'channels',
  'exchange_rates',
  'events',
  'watched_pairs',
  'search_history_entries',
];

Future<int> _count(AppDatabase db, String table) async {
  final row =
      await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
  return row.read<int>('c');
}

Future<int> _countBuiltinDictEntries(AppDatabase db) async {
  final row = await db.customSelect(
    'SELECT COUNT(*) AS c FROM dict_entries WHERE is_builtin = 1',
  ).getSingle();
  return row.read<int>('c');
}

Future<int> _countCustomDictEntries(AppDatabase db) async {
  final row = await db.customSelect(
    'SELECT COUNT(*) AS c FROM dict_entries WHERE is_builtin = 0',
  ).getSingle();
  return row.read<int>('c');
}

Future<bool> _hasBuiltinDict(
  AppDatabase db, {
  required String type,
  required String code,
}) async {
  final row = await db.customSelect(
    'SELECT COUNT(*) AS c FROM dict_entries WHERE type = ? AND code = ? AND is_builtin = 1',
    variables: [Variable.withString(type), Variable.withString(code)],
  ).getSingle();
  return row.read<int>('c') == 1;
}

/// 用 Drift Companion 向每张业务表塞一条最小有效行，随后验证 reset 的清理边界。
Future<void> _seedAll(AppDatabase db) async {
  final now = DateTime.utc(2024, 1, 1);

  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: 'acc-1',
          accountType: 'bank',
          sovereigntyRegion: 'CN',
          institutionName: 'ICBC',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.channels).insert(
        ChannelsCompanion.insert(
          id: 'ch-1',
          name: '电汇',
          transferProtocol: 'SWIFT',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.accountChannels).insert(
        AccountChannelsCompanion.insert(
          accountId: 'acc-1',
          channelId: 'ch-1',
          createdAt: now,
        ),
      );
  await db.into(db.assets).insert(
        AssetsCompanion.insert(
          id: 'a-1',
          accountId: 'acc-1',
          assetType: 'FX_ASSET',
          quantity: '1',
          currency: 'CNY',
          status: 'HOLDING',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.assetCostHistory).insert(
        AssetCostHistoryCompanion.insert(
          id: 'ach-1',
          assetId: 'a-1',
          quantity: '1',
          currency: 'CNY',
          source: 'manual',
          triggerTime: now,
          createdAt: now,
        ),
      );
  await db.into(db.assetPriceHistory).insert(
        AssetPriceHistoryCompanion.insert(
          id: 'aph-1',
          assetId: 'a-1',
          price: '100',
          currency: 'CNY',
          source: 'manual',
          triggerTime: now,
          createdAt: now,
        ),
      );
  await db.into(db.cards).insert(
        CardsCompanion.insert(
          id: 'c-1',
          accountId: 'acc-1',
          cardOrganization: 'VISA',
          cardNoMasked: '**** 1234',
          cardType: 'credit',
          expireMonth: 12,
          expireYear: 2030,
          issuerName: 'ICBC',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.exchangeRates).insert(
        ExchangeRatesCompanion.insert(
          id: 'er-1',
          pairKey: 'USD/CNY',
          baseCurrency: 'USD',
          quoteCurrency: 'CNY',
          rate: '7.1',
          asOfTime: now,
          updatedAt: now,
          source: 'manual',
          snapshotType: 'DAILY',
        ),
      );
  await db.into(db.events).insert(
        EventsCompanion.insert(
          id: 'e-1',
          eventType: 'TEST',
          relatedModel: 'asset',
          relatedId: 'a-1',
          triggerTime: now,
          status: 'triggered',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.watchedPairs).insert(
        WatchedPairsCompanion.insert(
          pairKey: 'USD/CNY',
          baseCurrency: 'USD',
          quoteCurrency: 'CNY',
          createdAt: now,
        ),
      );
  await db.into(db.searchHistoryEntries).insert(
        SearchHistoryEntriesCompanion.insert(
          kind: 'route',
          uniqueKey: 'dashboard',
          query: const Value('dash'),
          feature: const Value('global_search'),
          targetId: const Value('dashboard'),
          label: const Value('仪表盘'),
          sublabel: const Value('/dashboard'),
          visitedAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.dictEntries).insert(
        DictEntriesCompanion.insert(
          type: 'SOVEREIGNTY_REGION',
          code: 'ZZ_TEST',
          name: '测试地区',
          nameEn: const Value('Test Region'),
          sortOrder: const Value(1999),
          isBuiltin: const Value(false),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late PinStore pin;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pin = PinStore(
      storage: InMemoryPinKv(),
      kdf: PasswordKdf(memoryKib: 1024, iterations: 1, hashLength: 32),
    );
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('清空业务表与自定义字典，但保留内置字典', () async {
    await _seedAll(db);
    final builtinBefore = await _countBuiltinDictEntries(db);
    expect(builtinBefore, greaterThan(0));
    expect(await _countCustomDictEntries(db), 1);
    for (final t in _clearedTables) {
      expect(await _count(db, t), 1, reason: '前置插入 $t 应为 1 行');
    }

    final uc = ResetAllDataUseCase(
      snapshot: DbSnapshotService(db, CryptoService()),
      pinStore: pin,
    );
    final r = await uc();
    expect(r.isOk, isTrue);

    for (final t in _clearedTables) {
      expect(await _count(db, t), 0, reason: 'reset 后 $t 应清空');
    }
    expect(await _countCustomDictEntries(db), 0);
    expect(await _countBuiltinDictEntries(db), builtinBefore);
    expect(
      await _hasBuiltinDict(
        db,
        type: 'SOVEREIGNTY_REGION',
        code: 'HK',
      ),
      isTrue,
    );
    expect(
      await _hasBuiltinDict(
        db,
        type: 'TRANSFER_PROTOCOL',
        code: 'SWIFT',
      ),
      isTrue,
    );
    expect(
      await _hasBuiltinDict(
        db,
        type: 'CURRENCY',
        code: 'CNY',
      ),
      isTrue,
    );
  });

  test('默认保留 PIN；clearPin=true 才清 PIN', () async {
    await pin.setPin('123456');
    expect(await pin.hasPin(), isTrue);

    final uc = ResetAllDataUseCase(
      snapshot: DbSnapshotService(db, CryptoService()),
      pinStore: pin,
    );

    final r1 = await uc();
    expect(r1.isOk, isTrue);
    expect(await pin.hasPin(), isTrue, reason: '默认不应清 PIN');

    final r2 = await uc(clearPin: true);
    expect(r2.isOk, isTrue);
    expect(await pin.hasPin(), isFalse);
  });

  test('空库 reset 幂等：业务表为 0，内置字典保留', () async {
    final builtinBefore = await _countBuiltinDictEntries(db);
    final uc = ResetAllDataUseCase(
      snapshot: DbSnapshotService(db, CryptoService()),
      pinStore: pin,
    );
    final r = await uc();
    expect(r.isOk, isTrue);
    for (final t in _clearedTables) {
      expect(await _count(db, t), 0);
    }
    expect(await _countCustomDictEntries(db), 0);
    expect(await _countBuiltinDictEntries(db), builtinBefore);
  });

  test('PIN 清理失败（clearPin=true）时返回 StorageError', () async {
    final throwingPin = PinStore(
      storage: _ThrowingKv(),
      kdf: PasswordKdf(memoryKib: 1024, iterations: 1, hashLength: 32),
    );
    final uc = ResetAllDataUseCase(
      snapshot: DbSnapshotService(db, CryptoService()),
      pinStore: throwingPin,
    );

    expect((await uc()).isOk, isTrue);

    final r = await uc(clearPin: true);
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<StorageError>());
  });
}

class _ThrowingKv implements PinKeyValueStore {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async => throw StateError('kv delete failed');
}
