import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../domain/repositories/db_snapshot_repository.dart';
import '../db/database.dart';

/// 所有业务表 → 行 JSON 的快照导出/导入。
///
/// 使用 Drift 生成的 `toJson()` / `fromJson()`，忠实序列化每列；
/// 导入时先 `deleteAll` 清空各表再 `batch insert`，以保证副本一致。
///
/// 安全约束：
/// - 卡号 / CVV 的 AES-GCM 密文（`card_no_ciphertext` / `cvv_ciphertext`）
///   是用设备 Keystore 中的主密钥派生子密钥加密的，跨设备恢复时不可能
///   解密；因此在快照中**直接剥离**，避免把无效密文随备份外泄。导入后
///   用户需在新设备重新录入卡号 / CVV。
/// - 外层备份包本身仍然通过 Argon2id(password) → AES-GCM（
///   [CryptoPurpose.backup]）包裹，保障即便 JSON 被拿到也不可读。
class DbSnapshotService implements DbSnapshotRepository {
  const DbSnapshotService(this._db);

  final AppDatabase _db;

  static const _cardSensitiveFields = {
    'card_no_ciphertext',
    'cvv_ciphertext',
  };

  Map<String, dynamic> _stripCard(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.of(json);
    for (final k in _cardSensitiveFields) {
      copy.remove(k);
    }
    return copy;
  }

  /// 表名到 `List<Row JSON>` 的映射；顺序稳定（遵循外键依赖）。
  @override
  Future<Map<String, List<Map<String, dynamic>>>> export() async {
    return {
      'accounts': (await _db.select(_db.accounts).get())
          .map((r) => r.toJson())
          .toList(),
      'assets':
          (await _db.select(_db.assets).get()).map((r) => r.toJson()).toList(),
      'asset_cost_history': (await _db.select(_db.assetCostHistory).get())
          .map((r) => r.toJson())
          .toList(),
      'cards': (await _db.select(_db.cards).get())
          .map((r) => _stripCard(r.toJson()))
          .toList(),
      'channels': (await _db.select(_db.channels).get())
          .map((r) => r.toJson())
          .toList(),
      'account_channels': (await _db.select(_db.accountChannels).get())
          .map((r) => r.toJson())
          .toList(),
      'exchange_rates': (await _db.select(_db.exchangeRates).get())
          .map((r) => r.toJson())
          .toList(),
      'events':
          (await _db.select(_db.events).get()).map((r) => r.toJson()).toList(),
      'asset_price_history': (await _db.select(_db.assetPriceHistory).get())
          .map((r) => r.toJson())
          .toList(),
      'watched_pairs': (await _db.select(_db.watchedPairs).get())
          .map((r) => r.toJson())
          .toList(),
    };
  }

  /// 以快照覆盖当前数据库；外键按 accounts → cards/assets，channels / rates 独立，
  /// events 与 asset_price_history 最后写入。
  @override
  Future<void> restore(Map<String, List<Map<String, dynamic>>> snap) async {
    await _db.transaction(() async {
      // 清空顺序：子 → 父（account_channels 依赖 accounts/channels）
      await _db.delete(_db.assetPriceHistory).go();
      await _db.delete(_db.assetCostHistory).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.watchedPairs).go();
      await _db.delete(_db.accountChannels).go();
      await _db.delete(_db.channels).go();
      await _db.delete(_db.cards).go();
      await _db.delete(_db.assets).go();
      await _db.delete(_db.accounts).go();

      await _batchInsert(
        _db.accounts,
        snap['accounts'] ?? const [],
        AccountRow.fromJson,
      );
      await _batchInsert(
        _db.assets,
        snap['assets'] ?? const [],
        AssetRow.fromJson,
      );
      await _batchInsert(
        _db.assetCostHistory,
        snap['asset_cost_history'] ?? const [],
        AssetCostHistoryRow.fromJson,
      );
      await _batchInsert(
        _db.cards,
        snap['cards'] ?? const [],
        CardRow.fromJson,
      );
      await _batchInsert(
        _db.channels,
        snap['channels'] ?? const [],
        ChannelRow.fromJson,
      );
      await _batchInsert(
        _db.accountChannels,
        snap['account_channels'] ?? const [],
        AccountChannelRow.fromJson,
      );
      await _batchInsert(
        _db.exchangeRates,
        snap['exchange_rates'] ?? const [],
        ExchangeRateRow.fromJson,
      );
      await _batchInsert(
        _db.events,
        snap['events'] ?? const [],
        EventRow.fromJson,
      );
      await _batchInsert(
        _db.assetPriceHistory,
        snap['asset_price_history'] ?? const [],
        AssetPriceHistoryRow.fromJson,
      );
      await _batchInsert(
        _db.watchedPairs,
        snap['watched_pairs'] ?? const [],
        WatchedPairRow.fromJson,
      );
    });
  }

  /// 在单个事务里截断全部业务表（按 child → parent 顺序避免外键冲突）。
  @override
  Future<void> truncateAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.assetPriceHistory).go();
      await _db.delete(_db.assetCostHistory).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.accountChannels).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.watchedPairs).go();
      await _db.delete(_db.cards).go();
      await _db.delete(_db.assets).go();
      await _db.delete(_db.channels).go();
      await _db.delete(_db.accounts).go();
    });
  }

  Future<void> _batchInsert<T extends Insertable<dynamic>>(
    TableInfo table,
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (rows.isEmpty) return;
    await _db.batch((b) {
      for (final r in rows) {
        // fromJson 内部做强制类型转换，JSON 字段类型不符时抛 CastError/TypeError。
        // 在此捕获并转换为 StorageError，使异常以 Future error 形式传播，
        // 确保外层 transaction() 能感知到并执行 ROLLBACK。
        try {
          b.insert(table, fromJson(r));
        } catch (e) {
          throw StorageError(
            'restore: failed to deserialize row in ${table.actualTableName}: $e',
          );
        }
      }
    });
  }
}
