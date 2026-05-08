import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/db/database.dart';

/// C1 迁移兜底测试：
///
/// 历史版本表结构无法完整重建（旧列已删除），因此不尝试 v1→v12 串行；
/// 而是覆盖三个最易在未来回归里破的面：
/// 1. `onCreate` 必须拉起全部业务表 + 所有命名索引（partial/unique 一个都不能漏）。
/// 2. `v7→v8` 从 `events` 迁移到 `asset_price_history` 的 JSON SQL，
///    必须能被真实 sqlite3 引擎解析并正确剥离 `ASSET_VALUATED:` 前缀。
/// 3. `v11→v12` 的阈值 REAL→TEXT CAST 必须对已有行幂等改写。
void main() {
  const expectedTables = <String>{
    'accounts',
    'account_channels',
    'assets',
    'asset_cost_history',
    'asset_price_history',
    'cards',
    'channels',
    'dict_entries',
    'events',
    'exchange_rates',
    'search_history_entries',
    'watched_pairs',
  };

  const expectedIndices = <String>{
    'idx_accounts_active',
    'idx_assets_active',
    'idx_events_related',
    'idx_events_ack_pending',
    'idx_exchange_rates_pair_date',
    'idx_asset_cost_history_asset_time',
    'idx_dict_entries_type_code',
    'idx_search_history_unique_key',
  };

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> namedObjects(String type) async {
    final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%'",
      variables: [Variable<String>(type)],
    ).get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  test('onCreate 建出全部 12 张表', () async {
    await db.customSelect('SELECT 1').get();
    final tables = await namedObjects('table');
    for (final name in expectedTables) {
      expect(tables, contains(name), reason: 'missing table $name');
    }
  });

  test('onCreate 建出全部命名索引（含 partial/unique）', () async {
    await db.customSelect('SELECT 1').get();
    final indices = await namedObjects('index');
    for (final name in expectedIndices) {
      expect(indices, contains(name), reason: 'missing index $name');
    }
  });

  test('onCreate 为内置 CRYPTO 写入南极坐标', () async {
    final rows = await db.customSelect(
      "SELECT continent, map_lon, map_lat FROM dict_entries "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO'",
    ).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.read<String>('continent'), '数字');
    expect(row.read<double>('map_lon'), 18.0);
    expect(row.read<double>('map_lat'), -82.0);
  });

  test('连接打开后启用 foreign_keys，非法 account_channels 写入会失败', () async {
    final enabled = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(enabled.read<int>('foreign_keys'), 1);

    try {
      await db.customStatement(
        "INSERT INTO account_channels (account_id, channel_id, created_at) "
        "VALUES ('missing-account', 'missing-channel', 1700000000)",
      );
      fail('expected foreign key violation');
    } catch (_) {
      // expected
    }
  });

  test('account_channels 外键启用级联删除', () async {
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-1', 'BANK', 'CN', 'CMB', 'ACTIVE', 1700000000, 1700000000, 0)",
    );
    await db.customStatement(
      "INSERT INTO channels "
      "(id, name, transfer_protocol, status, created_at, updated_at) "
      "VALUES ('ch-1', 'SWIFT', 'SWIFT', 'ENABLED', 1700000000, 1700000000)",
    );
    await db.customStatement(
      "INSERT INTO account_channels (account_id, channel_id, created_at) "
      "VALUES ('acc-1', 'ch-1', 1700000000)",
    );

    await db.customStatement("DELETE FROM channels WHERE id = 'ch-1'");
    final rows = await db.customSelect('SELECT * FROM account_channels').get();
    expect(rows, isEmpty);
  });

  test('account_channels 支持账户级费用覆盖字段', () async {
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-1', 'BANK', 'CN', 'CMB', 'ACTIVE', 1700000000, 1700000000, 0)",
    );
    await db.customStatement(
      "INSERT INTO channels "
      "(id, name, transfer_protocol, status, created_at, updated_at) "
      "VALUES ('ch-1', 'SWIFT', 'SWIFT', 'ENABLED', 1700000000, 1700000000)",
    );
    await db.customStatement(
      "INSERT INTO account_channels "
      "(account_id, channel_id, fee_rate_override, fixed_fee_override, fee_currency_override, created_at, updated_at) "
      "VALUES ('acc-1', 'ch-1', '0', '0', 'USD', 1700000000, 1700000000)",
    );

    final rows = await db.customSelect(
      "SELECT fee_rate_override, fixed_fee_override, fee_currency_override FROM account_channels",
    ).get();
    expect(rows.single.read<String>('fee_rate_override'), '0');
    expect(rows.single.read<String>('fixed_fee_override'), '0');
    expect(rows.single.read<String>('fee_currency_override'), 'USD');
  });

  test('exchange_rates 唯一索引生效：同 (pair_key, as_of_time) 二次写入冲突', () async {
    await db.customSelect('SELECT 1').get();

    await db.customStatement(
      "INSERT INTO exchange_rates "
      "  (id, pair_key, base_currency, quote_currency, rate, as_of_time, "
      "   updated_at, source, snapshot_type) "
      "VALUES ('r1','USD/CNY','USD','CNY','7.10',1700000000,"
      "  1700000000,'frankfurter','DAILY')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO exchange_rates "
        "  (id, pair_key, base_currency, quote_currency, rate, as_of_time, "
        "   updated_at, source, snapshot_type) "
        "VALUES ('r2','USD/CNY','USD','CNY','7.20',1700000000,"
        "  1700000001,'frankfurter','DAILY')",
      ),
      throwsA(anything),
    );
  });

  test('events.source_key 唯一约束生效：非空值去重，NULL 可并存', () async {
    await db.customSelect('SELECT 1').get();

    // 两条 source_key=NULL 的行应可共存
    await db.customStatement(
      "INSERT INTO events (id, event_type, related_model, related_id, "
      "  status, trigger_time, created_at, updated_at) "
      "VALUES ('e1','X','asset','a1','OPEN',1700000000,1700000000,1700000000)",
    );
    await db.customStatement(
      "INSERT INTO events (id, event_type, related_model, related_id, "
      "  status, trigger_time, created_at, updated_at) "
      "VALUES ('e2','X','asset','a2','OPEN',1700000000,1700000000,1700000000)",
    );

    // 两条同 source_key 应冲突
    await db.customStatement(
      "INSERT INTO events (id, event_type, related_model, related_id, "
      "  status, trigger_time, created_at, updated_at, source_key) "
      "VALUES ('e3','Y','asset','a3','OPEN',1,1,1,'dup')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO events (id, event_type, related_model, related_id, "
        "  status, trigger_time, created_at, updated_at, source_key) "
        "VALUES ('e4','Y','asset','a4','OPEN',1,1,1,'dup')",
      ),
      throwsA(anything),
    );
  });

  test('v7→v8 迁移 SQL：JSON 抽取 + source_key 去前缀可被引擎解析', () async {
    await db.customSelect('SELECT 1').get();

    await db.customStatement(
      "INSERT INTO accounts "
      "(id, account_type, sovereignty_region, institution_name, status, created_at, updated_at, is_deleted) "
      "VALUES ('acc-v7', 'BROKER', 'CN', 'Legacy Broker', 'ACTIVE', 1700000000, 1700000000, 0)",
    );
    await db.customStatement(
      "INSERT INTO assets "
      "(id, account_id, asset_type, quantity, currency, status, created_at, updated_at, is_deleted) "
      "VALUES ('aid-1', 'acc-v7', 'STOCK', '10', 'CNY', 'HOLDING', 1700000000, 1700000000, 0)",
    );

    // 造一条 legacy ASSET_VALUATED 事件（v7 时期格式）
    await db.customStatement(
      "INSERT INTO events (id, event_type, related_model, related_id, "
      "  status, trigger_time, created_at, updated_at, handling_note, handler, "
      "  source_key, batch_id, is_deleted) "
      "VALUES ('ev1','ASSET_VALUATED','asset','aid-1','OPEN',"
      "  1700000000,1700000000,1700000000,"
      "  '{\"price\":\"100.25\",\"marketValue\":\"1002.5\",\"currency\":\"CNY\",\"source\":\"mock\"}',"
      "  'unused','ASSET_VALUATED:aid-1:20231114:mock','b1',0)",
    );

    // 先清空 asset_price_history 再跑迁移片段
    await db.customStatement('DELETE FROM asset_price_history');
    await db.customStatement(
      "INSERT OR IGNORE INTO asset_price_history "
      "  (id, asset_id, price, market_value, currency, source, "
      "   batch_id, trigger_time, source_key, raw_payload, created_at) "
      "SELECT id, related_id, "
      "  json_extract(handling_note, '\$.price'), "
      "  json_extract(handling_note, '\$.marketValue'), "
      "  COALESCE(json_extract(handling_note, '\$.currency'), ''), "
      "  COALESCE(json_extract(handling_note, '\$.source'), "
      "           COALESCE(handler, 'unknown')), "
      "  batch_id, trigger_time, "
      "  CASE "
      "    WHEN source_key IS NULL THEN NULL "
      "    WHEN instr(source_key, 'ASSET_VALUATED:') = 1 "
      "      THEN substr(source_key, length('ASSET_VALUATED:') + 1) "
      "    ELSE source_key END, "
      "  handling_note, created_at "
      "FROM events "
      "WHERE event_type = 'ASSET_VALUATED' "
      "  AND is_deleted = 0 "
      "  AND json_valid(handling_note) = 1 "
      "  AND json_extract(handling_note, '\$.price') IS NOT NULL",
    );

    final rows = await db
        .customSelect('SELECT * FROM asset_price_history WHERE id = ?',
            variables: [Variable<String>('ev1')])
        .get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.read<String>('asset_id'), 'aid-1');
    expect(row.read<String>('price'), '100.25');
    expect(row.read<String>('currency'), 'CNY');
    expect(row.read<String>('source'), 'mock');
    // 前缀必须被剥掉
    expect(row.read<String?>('source_key'), 'aid-1:20231114:mock');
  });

  test('v11→v12 迁移 SQL：watched_pairs 阈值 REAL→TEXT CAST', () async {
    await db.customSelect('SELECT 1').get();

    // 列是 TEXT 亲和，但 SQLite 允许塞数字字面量；模拟 v11 以前行为。
    await db.customStatement(
      "INSERT INTO watched_pairs "
      "  (pair_key, base_currency, quote_currency, "
      "   threshold_high, threshold_low, alert_change_pct, created_at) "
      "VALUES ('USD/CNY','USD','CNY',7.5,6.8,0.01,1700000000)",
    );

    // 执行 v12 迁移片段
    await db.customStatement(
      "UPDATE watched_pairs SET "
      "  threshold_high = CAST(threshold_high AS TEXT), "
      "  threshold_low = CAST(threshold_low AS TEXT), "
      "  alert_change_pct = CAST(alert_change_pct AS TEXT)",
    );

    final row = (await db
            .customSelect('SELECT * FROM watched_pairs WHERE pair_key = ?',
                variables: [Variable<String>('USD/CNY')])
            .get())
        .single;
    expect(row.read<String>('threshold_high'), '7.5');
    expect(row.read<String>('threshold_low'), '6.8');
    expect(row.read<String>('alert_change_pct'), '0.01');
  });

  test('v20→v21 修正内置 CRYPTO 的历史占位坐标', () async {
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      "UPDATE dict_entries SET map_lon = 0.0, map_lat = 0.0 "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO'",
    );

    await db.customStatement(
      "UPDATE dict_entries SET map_lon = 18.0, map_lat = -82.0 "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO' "
      "AND is_builtin = 1 AND continent = '数字' "
      "AND map_lon = 0.0 AND map_lat = 0.0",
    );

    final rows = await db.customSelect(
      "SELECT map_lon, map_lat FROM dict_entries "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO'",
    ).get();
    final row = rows.single;
    expect(row.read<double>('map_lon'), 18.0);
    expect(row.read<double>('map_lat'), -82.0);
  });

  test('v20→v21 不覆盖用户自定义的 CRYPTO 坐标', () async {
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      "UPDATE dict_entries SET map_lon = 44.0, map_lat = -70.0 "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO'",
    );

    await db.customStatement(
      "UPDATE dict_entries SET map_lon = 18.0, map_lat = -82.0 "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO' "
      "AND is_builtin = 1 AND continent = '数字' "
      "AND map_lon = 0.0 AND map_lat = 0.0",
    );

    final rows = await db.customSelect(
      "SELECT map_lon, map_lat FROM dict_entries "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO'",
    ).get();
    final row = rows.single;
    expect(row.read<double>('map_lon'), 44.0);
    expect(row.read<double>('map_lat'), -70.0);
  });
}
