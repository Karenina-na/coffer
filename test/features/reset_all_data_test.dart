import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/auth/pin_store.dart';
import 'package:gwp/core/crypto/password_kdf.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/backup/db_snapshot.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/domain/usecases/reset_all_data.dart';

/// 所有 10 张业务表清单——与 `@DriftDatabase.tables` 保持一致。
/// 若将来新增表但 `ResetAllDataUseCase` 忘记加 delete，这里会红。
const _allTables = <String>[
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
];

Future<int> _count(AppDatabase db, String table) async {
  final row =
      await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
  return row.read<int>('c');
}

/// 用 Drift Companion 向每张表塞一条最小有效行，随后验证 reset 能一次清空。
///
/// 走 Companion 而非 raw SQL：
///   1) Drift 默认把 DateTime 序列化为 unix 秒（integer），raw INSERT
///      用 ISO 字符串会静默写坏；Companion 由生成器保证字段/编码正确。
///   2) schema 演进时自动跟随，无需同步手工修改 INSERT 语句。
Future<void> _seedAll(AppDatabase db) async {
  final now = DateTime.utc(2024, 1, 1);

  // accounts（根表）
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
  // channels（独立）
  await db.into(db.channels).insert(
        ChannelsCompanion.insert(
          id: 'ch-1',
          name: '电汇',
          transferProtocol: 'WIRE',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
  // account_channels（junction，依赖 accounts + channels）
  await db.into(db.accountChannels).insert(
        AccountChannelsCompanion.insert(
          accountId: 'acc-1',
          channelId: 'ch-1',
          createdAt: now,
        ),
      );
  // assets（FK → accounts）
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
  // asset_cost_history（FK → assets）
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
  // asset_price_history（FK → assets）
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
  // cards（FK → accounts）
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
  // exchange_rates（独立）
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
  // events（独立）
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
  // watched_pairs（独立；主键 pair_key）
  await db.into(db.watchedPairs).insert(
        WatchedPairsCompanion.insert(
          pairKey: 'USD/CNY',
          baseCurrency: 'USD',
          quoteCurrency: 'CNY',
          createdAt: now,
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
    // 若某个用例提前 close 了 db，这里再 close 会抛；忽略即可。
    try {
      await db.close();
    } catch (_) {}
  });

  test('清空全部 10 张业务表（child → parent 顺序不触发 FK 冲突）', () async {
    await _seedAll(db);
    for (final t in _allTables) {
      expect(await _count(db, t), 1, reason: '前置插入 $t 应为 1 行');
    }

    final uc = ResetAllDataUseCase(snapshot: DbSnapshotService(db), pinStore: pin);
    final r = await uc();
    expect(r.isOk, isTrue);

    for (final t in _allTables) {
      expect(await _count(db, t), 0, reason: 'reset 后 $t 应清空');
    }
  });

  test('默认保留 PIN；clearPin=true 才清 PIN', () async {
    await pin.setPin('123456');
    expect(await pin.hasPin(), isTrue);

    final uc = ResetAllDataUseCase(snapshot: DbSnapshotService(db), pinStore: pin);

    // clearPin 默认 false → 数据清了但 PIN 保留
    final r1 = await uc();
    expect(r1.isOk, isTrue);
    expect(await pin.hasPin(), isTrue, reason: '默认不应清 PIN');

    // clearPin=true → PIN 一并清除
    final r2 = await uc(clearPin: true);
    expect(r2.isOk, isTrue);
    expect(await pin.hasPin(), isFalse);
  });

  test('空库 reset 幂等：依然返回 Ok，表计数仍为 0', () async {
    final uc = ResetAllDataUseCase(snapshot: DbSnapshotService(db), pinStore: pin);
    final r = await uc();
    expect(r.isOk, isTrue);
    for (final t in _allTables) {
      expect(await _count(db, t), 0);
    }
  });

  test('PIN 清理失败（clearPin=true）时返回 StorageError', () async {
    // 构造一个「读可用、删必抛」的 KV，模拟平台 Keystore 异常。
    final throwingPin = PinStore(
      storage: _ThrowingKv(),
      kdf: PasswordKdf(memoryKib: 1024, iterations: 1, hashLength: 32),
    );
    final uc = ResetAllDataUseCase(snapshot: DbSnapshotService(db), pinStore: throwingPin);

    // 默认 clearPin=false 不会触碰 PIN，应成功。
    expect((await uc()).isOk, isTrue);

    // clearPin=true 时走 PIN.clear()，底层抛异常 → StorageError。
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
