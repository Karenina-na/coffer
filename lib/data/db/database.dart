import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/crypto/key_derivation.dart';
import '../../core/crypto/secure_key_store.dart';
import 'tables/accounts.dart';
import 'tables/account_channels.dart';
import 'tables/asset_cost_history.dart';
import 'tables/asset_price_history.dart';
import 'tables/assets.dart';
import 'tables/cards.dart';
import 'tables/channels.dart';
import 'tables/dict_entries.dart';
import 'tables/events.dart';
import 'tables/exchange_rates.dart';
import 'tables/search_history_entries.dart';
import 'tables/watched_pairs.dart';
import 'daos/account_dao.dart';
import 'daos/account_channel_dao.dart';
import 'daos/asset_cost_history_dao.dart';
import 'daos/asset_dao.dart';
import 'daos/asset_price_history_dao.dart';
import 'daos/card_dao.dart';
import 'daos/channel_dao.dart';
import 'daos/dict_entry_dao.dart';
import 'daos/event_dao.dart';
import 'daos/exchange_rate_dao.dart';
import 'daos/search_history_dao.dart';
import 'daos/watched_pair_dao.dart';

part 'database.g.dart';

/// GWP 本地数据库。
///
/// 表定义严格对齐 doc/data-definitions.md。
/// 金额/数量列以 TEXT 存储十进制字符串，应用层以 [Decimal] 解析。
@DriftDatabase(
  tables: [
    Accounts,
    AccountChannels,
    Assets,
    AssetCostHistory,
    AssetPriceHistory,
    Cards,
    Channels,
    DictEntries,
    ExchangeRates,
    Events,
    SearchHistoryEntries,
    WatchedPairs,
  ],
  daos: [
    AccountDao,
    AccountChannelDao,
    AssetDao,
    AssetCostHistoryDao,
    AssetPriceHistoryDao,
    CardDao,
    ChannelDao,
    DictEntryDao,
    EventDao,
    ExchangeRateDao,
    SearchHistoryDao,
    WatchedPairDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 软删除过滤走 partial index，查询命中 is_deleted=0 的行。
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_accounts_active '
        'ON accounts (id) WHERE is_deleted = 0',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_assets_active '
        'ON assets (account_id) WHERE is_deleted = 0',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_related '
        'ON events (related_model, related_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_ack_pending '
        "ON events (ack_requirement, ack_status) "
        "WHERE ack_requirement = 'REQUIRED' AND ack_status = 'PENDING' "
        'AND is_deleted = 0',
      );
      // 同一币对同一天只允许一条快照，Frankfurter / manual / mock
      // 任一源的重复写入都会被 ON CONFLICT 覆盖为最新值。
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_exchange_rates_pair_date '
        'ON exchange_rates (pair_key, as_of_time)',
      );
      // 资产成本历史按 (asset_id, trigger_time DESC) 查询，避免全表扫描。
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_asset_cost_history_asset_time '
        'ON asset_cost_history (asset_id, trigger_time DESC)',
      );
      // dict_entries 的 (type, code) 逻辑唯一，用 UNIQUE 索引约束；
      // 同一 type 下按 sort_order 排序时也会命中此索引的前缀。
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_dict_entries_type_code '
        'ON dict_entries (type, code)',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_search_history_unique_key '
        'ON search_history_entries (unique_key)',
      );
      await _seedBuiltinDictEntries(this);
      await seedBuiltinChannels(this);
    },
    onUpgrade: (m, from, to) async {
      await m.database.transaction(() async {
        if (from < 2) {
          await m.createTable(watchedPairs);
        }
        if (from < 3) {
          // v2 → v3：事件表新增字段 + ack/幂等索引
          await m.addColumn(events, events.refs);
          await m.addColumn(events, events.batchId);
          await m.addColumn(events, events.sourceKey);
          await m.addColumn(events, events.dueAt);
          await m.addColumn(events, events.ackRequirement);
          await m.addColumn(events, events.ackStatus);
          await m.addColumn(events, events.ackAt);
          await m.addColumn(events, events.ackNote);
          await m.addColumn(events, events.isDeleted);
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_events_source_key '
            'ON events (source_key) WHERE source_key IS NOT NULL',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_events_ack_pending '
            "ON events (ack_requirement, ack_status) "
            "WHERE ack_requirement = 'REQUIRED' AND ack_status = 'PENDING' "
            'AND is_deleted = 0',
          );
        }
        if (from < 4) {
          // v3 → v4：Channel 从「类型对」改为「协议/网络定义」；账户通过
          // account_channels 关联多条通道。旧的 src/tgt 列与历史数据丢弃。
          await customStatement('DROP TABLE IF EXISTS channels');
          await m.createTable(channels);
          await m.createTable(accountChannels);
        }
        if (from < 5) {
          // v4 → v5：Card 新增支持币种字段。
          await m.addColumn(cards, cards.supportsAllCurrencies);
          await m.addColumn(cards, cards.supportedCurrencies);
        }
        if (from < 6) {
          // v5 → v6：汇率表去重。
          //  1) DAILY 快照的 as_of_time 归一化到 UTC 当日 00:00（存储为
          //     unix 秒，date('now') 取 UTC 日），解决
          //     DateTime.now() 写入造成的毫秒级散点；
          //  2) 同 (pair_key, as_of_time) 去重，保留 updated_at 最大者；
          //  3) 删除旧索引，创建 UNIQUE 索引以约束后续写入。
          await customStatement(
            "UPDATE exchange_rates "
            "SET as_of_time = CAST(strftime('%s', "
            "  date(as_of_time, 'unixepoch')) AS INTEGER) "
            "WHERE snapshot_type = 'DAILY'",
          );
          await customStatement(
            'DELETE FROM exchange_rates WHERE id IN ('
            '  SELECT e1.id FROM exchange_rates e1 '
            '  WHERE EXISTS ('
            '    SELECT 1 FROM exchange_rates e2 '
            '    WHERE e2.pair_key = e1.pair_key '
            '      AND e2.as_of_time = e1.as_of_time '
            '      AND (e2.updated_at > e1.updated_at '
            '        OR (e2.updated_at = e1.updated_at AND e2.id > e1.id))'
            '  )'
            ')',
          );
          await customStatement('DROP INDEX IF EXISTS idx_exchange_rates_pair');
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS '
            'idx_exchange_rates_pair_date '
            'ON exchange_rates (pair_key, as_of_time)',
          );
        }
        if (from < 7) {
          // v6 → v7：清除历史 mock 汇率。mock_seeder 之前会按锯齿公式
          // 伪造 7 天行情并覆盖周末/节假日；由于 Frankfurter 不返回这些
          // 日期，锯齿点得不到覆盖，首页曲线会出现「所有币对同一天一起
          // 跳起来」的伪信号。mock 现已彻底不再写入汇率。
          await customStatement(
            "DELETE FROM exchange_rates WHERE source = 'mock'",
          );
        }
        if (from < 8) {
          // v7 → v8：估值成功事件从 `events` 表迁移到独立的
          // `asset_price_history` 表。
          //
          // 设计动机：每日估值同步会在 `events` 里堆大量 ASSET_VALUATED
          // 行，淹没真正需要用户感知的告警；拆成两张表后，事件表只留操
          // 作型条目（失败、同步过期等），成功估值走审计日志，图表仍可
          // 查询。
          //
          // 迁移步骤：
          //  1) 建表
          //  2) 把 `events` 中 event_type='ASSET_VALUATED' 且未软删的记录
          //     按 handlingNote 里的 price / marketValue / currency / source
          //     一行一行 INSERT 到新表；sourceKey 去掉前缀，仅保留
          //     `{assetId}:{yyyymmdd}:{source}` 作为新表的幂等键
          //  3) 删除 events 表里所有 ASSET_VALUATED 行（含已软删）
          await m.createTable(assetPriceHistory);
          await customStatement(
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
          await customStatement(
            "DELETE FROM events WHERE event_type = 'ASSET_VALUATED'",
          );
        }
        if (from < 9) {
          // v8 → v9：WatchedPair 增加三列预警阈值（全部可空）。
          await m.addColumn(watchedPairs, watchedPairs.thresholdHigh);
          await m.addColumn(watchedPairs, watchedPairs.thresholdLow);
          await m.addColumn(watchedPairs, watchedPairs.alertChangePct);
        }
        if (from < 10) {
          // v9 → v10：新增资产成本价/数量调整历史表。
          await m.createTable(assetCostHistory);
        }
        if (from < 11) {
          // v10 → v11：资产成本历史加复合索引，避免全表扫描。
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_asset_cost_history_asset_time '
            'ON asset_cost_history (asset_id, trigger_time DESC)',
          );
        }
        if (from < 12) {
          // v11 → v12：WatchedPair 阈值字段从 REAL 迁移到 TEXT（Decimal 序列化），
          // 遵循「金额永远禁止 double」的项目约束。SQLite 列类型为动态类型，
          // 直接读取时将按 TEXT 亲和返回；已有 REAL 值可原地兼容，因此
          // 只需为新写入保证通过 Decimal.toString() 落地即可，无需重建表。
          // 为确保查询一致性，这里把现有 REAL 值统一 CAST 成 TEXT 存储。
          await customStatement(
            "UPDATE watched_pairs SET "
            "  threshold_high = CAST(threshold_high AS TEXT), "
            "  threshold_low = CAST(threshold_low AS TEXT), "
            "  alert_change_pct = CAST(alert_change_pct AS TEXT)",
          );
        }
        if (from < 13) {
          // v12 → v13：新增 dict_entries 表承载「转账协议 / 主权地区 /
          // 货币」三个业务字典，替代原来各自散落的 TextField / 硬编码
          // 预设。内置项随 migration 预置，并以 `is_builtin = true` 标
          // 记为不可删除，但允许用户改名。
          await m.createTable(dictEntries);
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_dict_entries_type_code '
            'ON dict_entries (type, code)',
          );
          await _seedBuiltinDictEntries(this);
        }
        if (from < 14) {
          // v13 → v14：account_channels 增加外键约束，防止孤儿关联。
          // 迁移时只保留父表仍存在的关联行，并在删除账户 / 通道时级联清理。
          await customStatement(
            'ALTER TABLE account_channels RENAME TO account_channels_old',
          );
          await m.createTable(accountChannels);
          await customStatement(
            'INSERT OR IGNORE INTO account_channels '
            '(account_id, channel_id, created_at) '
            'SELECT ac.account_id, ac.channel_id, ac.created_at '
            'FROM account_channels_old ac '
            'INNER JOIN accounts a ON a.id = ac.account_id '
            'INNER JOIN channels c ON c.id = ac.channel_id',
          );
          await customStatement('DROP TABLE account_channels_old');
        }
        if (from < 15) {
          // v14 → v15：dict_entries 新增地区 UI 元数据列（均可空，不影响
          // 已有的转账协议 / 货币条目）。对已有内置主权地区用 UPDATE 回填。
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN flag_emoji TEXT',
          );
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN continent TEXT',
          );
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN color_hex TEXT',
          );
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN map_lon REAL',
          );
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN map_lat REAL',
          );
          // 回填 14 个内置主权地区的 UI 元数据。
          await _backfillRegionMeta(this);
        }
        if (from < 16) {
          // v15 → v16：dict_entries 新增 parent_region 列，支持区域层级
          // 展示（如「欧盟 | 德国」）。EU 成员国由 CountryDataImporter
          // 在同步时自动填入，迁移只加列。
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN parent_region TEXT',
          );
        }
        if (from < 17) {
          // v16 → v17：调整内置转账协议预设。
          // 删除旧有的 RTGS / ONCHAIN / INTERNAL 三个协议。
          await customStatement(
            "DELETE FROM dict_entries "
            "WHERE type = 'TRANSFER_PROTOCOL' "
            "AND code IN ('RTGS', 'ONCHAIN', 'INTERNAL')",
          );
          // 将旧的 FPS（无歧义名）更新为「香港快速支付」，code 保持 FPS 不变
          // 以免现有通道关联断裂；同时补入 CHATS 与 UK_FPS。
          await customStatement(
            "UPDATE dict_entries "
            "SET name = '香港快速支付', name_en = 'HK FPS' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'FPS'",
          );
          final now17 =
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          await customStatement(
            "INSERT OR IGNORE INTO dict_entries "
            "(id, type, code, name, name_en, sort_order, is_builtin, is_deleted, created_at, updated_at) "
            "VALUES "
            "('builtin_tp_chats', 'TRANSFER_PROTOCOL', 'CHATS', '香港美元结算', 'CHATS', 165, 1, 0, $now17, $now17), "
            "('builtin_tp_uk_fps', 'TRANSFER_PROTOCOL', 'UK_FPS', '英国快速支付', 'UK Faster Payments', 175, 1, 0, $now17, $now17)",
          );
        }
        if (from < 18) {
          // v17 → v18：清理旧的内置主权地区集合；当前保留项目认可的金融国家/地区预设。
          // 删除不在新预设内的旧地区（用户自建的地区 is_builtin=0 不受影响）。
          await customStatement(
            "DELETE FROM dict_entries "
            "WHERE type = 'SOVEREIGNTY_REGION' AND is_builtin = 1 "
            "AND code NOT IN ('HK','CN','US','SG','GB','DE','FR','IT','JP','KR','TW','MY','CA','AU','EU','CRYPTO')",
          );
          // 把「中国香港」更名为「香港」（仅更新 NULL 或旧值，保留用户自定义）。
          await customStatement(
            "UPDATE dict_entries SET name = '香港' "
            "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'HK' "
            "AND name = '中国香港'",
          );
          final now18 =
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          // 补入 CRYPTO 虚拟地区（INSERT OR IGNORE 幂等）。
          await customStatement(
            "INSERT OR IGNORE INTO dict_entries "
            "(id, type, code, name, name_en, sort_order, is_builtin, is_deleted, "
            " flag_emoji, continent, color_hex, map_lon, map_lat, "
            " created_at, updated_at) "
            "VALUES ('builtin_sr_crypto', 'SOVEREIGNTY_REGION', 'CRYPTO', "
            "        '加密', 'Crypto', 160, 1, 0, "
            "        '🔐', '数字', '0xFF38BDF8', 18.0, -82.0, "
            "        $now18, $now18)",
          );
          // 回填当前内置金融地区集合的 UI 元数据（只写 NULL 列，不覆盖用户改动）。
          await _backfillRegionMeta(this);
        }
        if (from < 19) {
          await m.createTable(searchHistoryEntries);
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_search_history_unique_key '
            'ON search_history_entries (unique_key)',
          );
        }
        if (from < 20) {
          await customStatement(
            'ALTER TABLE account_channels ADD COLUMN fee_rate_override TEXT',
          );
          await customStatement(
            'ALTER TABLE account_channels ADD COLUMN fixed_fee_override TEXT',
          );
          await customStatement(
            'ALTER TABLE account_channels ADD COLUMN fee_currency_override TEXT',
          );
          await customStatement(
            'ALTER TABLE account_channels ADD COLUMN updated_at INTEGER',
          );
          await customStatement(
            'UPDATE account_channels SET updated_at = created_at '
            'WHERE updated_at IS NULL',
          );
        }
        if (from < 21) {
          await customStatement(
            "UPDATE dict_entries SET map_lon = 18.0, map_lat = -82.0 "
            "WHERE type = 'SOVEREIGNTY_REGION' AND code = 'CRYPTO' "
            "AND is_builtin = 1 AND continent = '数字' "
            "AND map_lon = 0.0 AND map_lat = 0.0",
          );
        }
        if (from < 22) {
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN anchor_lon REAL',
          );
          await customStatement(
            'ALTER TABLE dict_entries ADD COLUMN anchor_lat REAL',
          );
          await _backfillRegionAnchors(this);
        }
        if (from < 23) {
          final now23 =
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          await customStatement(
            "UPDATE channels SET transfer_protocol = 'FPS', updated_at = $now23 "
            "WHERE transfer_protocol = 'UK_FPS'",
          );
          await customStatement(
            "DELETE FROM dict_entries "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'UK_FPS'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'SWIFT', name_en = 'SWIFT' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'SWIFT'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'ACH', name_en = 'ACH' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'ACH'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'Faster Payment System', name_en = 'Faster Payment System' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'FPS'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'CNAPS', name_en = 'CNAPS' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'CNAPS'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'SEPA', name_en = 'SEPA' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'SEPA'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = 'CHATS', name_en = 'CHATS' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'CHATS'",
          );
          await _seedBuiltinDictEntries(this);
          await seedBuiltinChannels(this);
        }
        if (from < 24) {
          await customStatement(
            'ALTER TABLE channels ADD COLUMN is_builtin INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            "UPDATE channels SET is_builtin = 1 "
            "WHERE id IN ("
            "'builtin_ch_swift',"
            "'builtin_ch_hk_fps',"
            "'builtin_ch_gb_fps',"
            "'builtin_ch_hk_chats',"
            "'builtin_ch_cn_cny',"
            "'builtin_ch_us_ach'"
            ")",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '环球银行金融电信协会', name_en = 'Society for Worldwide Interbank Financial Telecommunication' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'SWIFT'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '美国自动清算所', name_en = 'Automated Clearing House' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'ACH'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '快速支付系统', name_en = 'Faster Payment System' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'FPS'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '中国现代化支付系统', name_en = 'China National Advanced Payment System' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'CNAPS'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '单一欧元支付区', name_en = 'Single Euro Payments Area' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'SEPA'",
          );
          await customStatement(
            "UPDATE dict_entries SET name = '港元即时支付结算系统', name_en = 'Clearing House Automated Transfer System' "
            "WHERE type = 'TRANSFER_PROTOCOL' AND code = 'CHATS'",
          );
          await _seedBuiltinDictEntries(this);
          await seedBuiltinChannels(this);
        }
        if (from < 25) {
          await _seedBuiltinDictEntries(this);
        }
      }); // end transaction
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// 预置「转账协议 / 主权地区 / 货币」三类内置字典。
///
/// 使用 `INSERT OR IGNORE`：既可用于 onCreate（首次建表），也可用于
/// onUpgrade（老库升级到 v13 时补齐），不会覆盖用户改过名的内置项。
Future<void> _seedBuiltinDictEntries(AppDatabase db) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  Future<void> seed(String type, List<List<Object?>> entries) async {
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final code = e[0] as String;
      final name = e[1] as String;
      final nameEn = e.length > 2 ? e[2] as String? : null;
      final sort = 100 + i * 10;
      await db.customStatement(
        'INSERT OR IGNORE INTO dict_entries '
        '(type, code, name, name_en, sort_order, is_builtin, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, 1, ?, ?)',
        [type, code, name, nameEn, sort, now, now],
      );
    }
  }

  // 转账协议：对齐 TransferProtocol enum。
  await seed('TRANSFER_PROTOCOL', const [
    ['SWIFT', '环球银行金融电信协会', 'Society for Worldwide Interbank Financial Telecommunication'],
    ['ACH', '美国自动清算所', 'Automated Clearing House'],
    ['FPS', '快速支付系统', 'Faster Payment System'],
    ['CNAPS', '中国现代化支付系统', 'China National Advanced Payment System'],
    ['SEPA', '单一欧元支付区', 'Single Euro Payments Area'],
    ['CHATS', '港元即时支付结算系统', 'Clearing House Automated Transfer System'],
  ]);

  // 主权地区：覆盖主要金融国家 / 地区；ISO 3166-1 alpha-2 + 区域/虚拟代码。
  await seed('SOVEREIGNTY_REGION', const [
    ['HK', '香港', 'Hong Kong'],
    ['CN', '中国大陆', 'China'],
    ['US', '美国', 'United States'],
    ['SG', '新加坡', 'Singapore'],
    ['GB', '英国', 'United Kingdom'],
    ['DE', '德国', 'Germany'],
    ['FR', '法国', 'France'],
    ['IT', '意大利', 'Italy'],
    ['JP', '日本', 'Japan'],
    ['KR', '韩国', 'South Korea'],
    ['TW', '中国台湾', 'Taiwan'],
    ['MY', '马来西亚', 'Malaysia'],
    ['CA', '加拿大', 'Canada'],
    ['AU', '澳大利亚', 'Australia'],
    ['EU', '欧盟', 'European Union'],
    ['CRYPTO', '加密', 'Crypto'],
  ]);

  // 回填地理元数据与地图锚点（onCreate 走这里；onUpgrade 分阶段回填）。
  await _backfillRegionMeta(db);
  await _backfillRegionAnchors(db);

  // 货币：ISO 4217 三位代码。
  await seed('CURRENCY', const [
    ['CNY', '人民币', 'Chinese Yuan'],
    ['USD', '美元', 'US Dollar'],
    ['GBP', '英镑', 'British Pound'],
    ['EUR', '欧元', 'Euro'],
    ['HKD', '港币', 'Hong Kong Dollar'],
  ]);
}

Future<void> seedBuiltinChannels(AppDatabase db) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final entries = <({
    String id,
    String name,
    String protocol,
    String? limitCurrency,
    String? regionRule,
  })>[
    (
      id: 'builtin_ch_swift',
      name: '环球银行金融电信协会通道',
      protocol: 'SWIFT',
      limitCurrency: null,
      regionRule: null,
    ),
    (
      id: 'builtin_ch_hk_fps',
      name: '香港快速支付系统通道',
      protocol: 'FPS',
      limitCurrency: 'HKD',
      regionRule: '{"allowedRegions":["HK"]}',
    ),
    (
      id: 'builtin_ch_gb_fps',
      name: '英国快速支付系统通道',
      protocol: 'FPS',
      limitCurrency: 'GBP',
      regionRule: '{"allowedRegions":["GB"]}',
    ),
    (
      id: 'builtin_ch_hk_chats',
      name: '香港即时支付结算系统通道',
      protocol: 'CHATS',
      limitCurrency: 'USD',
      regionRule: '{"allowedRegions":["HK"]}',
    ),
    (
      id: 'builtin_ch_cn_cny',
      name: '中国现代化支付系统通道',
      protocol: 'CNAPS',
      limitCurrency: 'CNY',
      regionRule: '{"allowedRegions":["CN"]}',
    ),
    (
      id: 'builtin_ch_us_ach',
      name: '美国自动清算所通道',
      protocol: 'ACH',
      limitCurrency: 'USD',
      regionRule: '{"allowedRegions":["US"]}',
    ),
  ];

  for (final entry in entries) {
    await db.customStatement(
      'INSERT OR IGNORE INTO channels '
      '(id, name, transfer_protocol, is_builtin, sovereignty_region_rule, limit_currency, status, created_at, updated_at) '
      'VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?)',
      [
        entry.id,
        entry.name,
        entry.protocol,
        entry.regionRule,
        entry.limitCurrency,
        'ENABLED',
        now,
        now,
      ],
    );
  }
}

/// 回填内置主权地区的地理元数据（flag_emoji / continent / color_hex / map_lon / map_lat）。
///
/// 使用 `UPDATE ... WHERE code = ? AND type = 'SOVEREIGNTY_REGION'`，
/// 只更新 NULL 列，避免覆盖用户已手动编辑的值。
Future<void> _backfillRegionMeta(AppDatabase db) async {
  // [code, flag, continent, colorHex, lon, lat]
  const regions = [
    ['HK', '🇭🇰', '亚太', '0xFFF59E0B', 114.1694, 22.3193],
    ['CN', '🇨🇳', '亚太', '0xFFEF4444', 104.1954, 35.8617],
    ['US', '🇺🇸', '美洲', '0xFF64748B', -98.5795, 39.8283],
    ['SG', '🇸🇬', '亚太', '0xFF22C55E', 103.8198, 1.3521],
    ['GB', '🇬🇧', '欧洲', '0xFFA78BFA', -3.4360, 55.3781],
    ['DE', '🇩🇪', '欧洲', '0xFF7B6BD4', 10.4515, 51.1657],
    ['FR', '🇫🇷', '欧洲', '0xFF8B5CF6', 2.2137, 46.2276],
    ['IT', '🇮🇹', '欧洲', '0xFF9F7AEA', 12.5674, 41.8719],
    ['JP', '🇯🇵', '亚太', '0xFFDC2626', 138.2529, 36.2048],
    ['KR', '🇰🇷', '亚太', '0xFF2563EB', 127.7669, 35.9078],
    ['TW', '🇹🇼', '亚太', '0xFF14B8A6', 120.9605, 23.6978],
    ['MY', '🇲🇾', '亚太', '0xFF06B6D4', 101.9758, 4.2105],
    ['CA', '🇨🇦', '美洲', '0xFF10B981', -106.3468, 56.1304],
    ['AU', '🇦🇺', '亚太', '0xFF0EA5E9', 133.7751, -25.2744],
    ['EU', '🇪🇺', '欧洲', '0xFF6366F1', 10.0, 50.0],
    ['CRYPTO', '🔐', '数字', '0xFF38BDF8', 18.0, -82.0],
  ];
  for (final r in regions) {
    await db.customStatement(
      'UPDATE dict_entries SET '
      "  flag_emoji = COALESCE(flag_emoji, ?), "
      "  continent = COALESCE(continent, ?), "
      "  color_hex = COALESCE(color_hex, ?), "
      "  map_lon = COALESCE(map_lon, ?), "
      "  map_lat = COALESCE(map_lat, ?) "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = ?",
      [r[1], r[2], r[3], r[4], r[5], r[0]],
    );
  }
}

/// 回填地区的地图展示锚点（优先用于金融中心点）。
///
/// 仅在 `anchor_lon/anchor_lat` 为空时写入，避免覆盖用户手调结果。
Future<void> _backfillRegionAnchors(AppDatabase db) async {
  // [code, anchorLon, anchorLat]
  const anchors = [
    ['HK', 114.1694, 22.3193],
    ['CN', 121.4737, 31.2304],
    ['US', -74.0060, 40.7128],
    ['SG', 103.8198, 1.3521],
    ['GB', -0.1276, 51.5072],
    ['CA', -79.3832, 43.6532],
    ['DE', 8.6821, 50.1109],
    ['FR', 2.3522, 48.8566],
    ['IT', 9.1900, 45.4642],
    ['JP', 139.6917, 35.6895],
    ['KR', 126.9780, 37.5665],
    ['TW', 121.5654, 25.0330],
    ['MY', 101.6869, 3.1390],
    ['AU', 151.2093, -33.8688],
    ['EU', 4.3517, 50.8503],
    ['CRYPTO', 18.0, -82.0],
  ];
  for (final r in anchors) {
    await db.customStatement(
      'UPDATE dict_entries SET '
      "  anchor_lon = COALESCE(anchor_lon, ?), "
      "  anchor_lat = COALESCE(anchor_lat, ?) "
      "WHERE type = 'SOVEREIGNTY_REGION' AND code = ?",
      [r[1], r[2], r[0]],
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'gwp.db');
    final file = File(dbPath);

    // 加密启用标记：与密库一起落盘，证明当前文件由加密流程写入。
    // 用户已明确声明不保留切换前的明文数据：检测到本地只有明文 DB（无
    // 标记文件）时，直接删除明文 DB 与 WAL/SHM 副本，让加密流程新建密库。
    final marker = File(p.join(dir.path, 'gwp.db.encrypted'));
    if (await file.exists() && !await marker.exists()) {
      if (await isPlaintextSqliteDatabase(file)) {
        await _deleteDatabaseFiles(dbPath);
      }
    }

    // 从平台 Keystore 的主密钥派生数据库整库加密密钥（HKDF-SHA256，
    // purpose = "db.sqlcipher"）。以十六进制形式作为 PRAGMA key 的 raw key
    // 传入，绕开字符串转义风险；SQLite3MultipleCiphers 的 `x'...'`
    // 语法将其视为 32 字节原始密钥。
    final master = await SecureKeyStore().loadOrCreateMaster();
    final dbKey = await KeyDerivation().derive(
      master: master,
      purpose: 'db.sqlcipher',
    );
    final keyBytes = await dbKey.extractBytes();
    final keyHex = _toHex(keyBytes);

    if (!await marker.exists()) {
      await marker.writeAsString('v1');
    }

    return NativeDatabase(
      file,
      setup: (raw) {
        // PRAGMA key 必须是 SQLite 打开后的第一条语句，否则 cipher 页头
        // 不会被解析，后续读写全部失败。
        raw.execute("PRAGMA key = \"x'$keyHex'\";");
        raw.execute('PRAGMA foreign_keys = ON;');
        // 轻量自检：跑一次简单查询，若密钥错误/未启用密码库会立即报错，
        // 而不是拖到第一条业务 SQL 才暴露。
        raw.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}

Future<bool> isPlaintextSqliteDatabase(File file) async {
  if (!await file.exists()) return false;
  try {
    final input = await file.open();
    try {
      final header = await input.read(16);
      return String.fromCharCodes(header).startsWith('SQLite format 3');
    } finally {
      await input.close();
    }
  } catch (_) {
    return false;
  }
}

Future<void> _deleteDatabaseFiles(String dbPath) async {
  for (final path in [dbPath, '$dbPath-wal', '$dbPath-shm']) {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// 把字节数组格式化为紧凑十六进制串（无分隔、小写），供 `PRAGMA key` 的
/// `x'...'` 二进制字面量使用。
String _toHex(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
