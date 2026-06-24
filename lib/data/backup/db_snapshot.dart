import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../domain/repositories/db_snapshot_repository.dart';
import '../crypto_service.dart';
import '../db/daos/dict_entry_dao.dart';
import '../db/database.dart';

/// 所有业务表 → 行 JSON 的快照导出/导入。
///
/// 使用 Drift 生成的 `toJson()` / `fromJson()`，忠实序列化每列；
/// 导入时先 `deleteAll` 清空各表再 `batch insert`，以保证副本一致。
///
/// 安全约束：
/// - CVV 的 AES-GCM 密文（`cvv_ciphertext`）仍然不进入快照，避免把高度敏感
///   的校验码跨设备迁移；恢复后用户需重新录入 CVV。
/// - 卡号密文本身是设备绑定的，不能直接跨设备恢复；因此导出时会解密出卡号
///   明文并以 `card_no_backup` 形式进入快照，导入时再用当前设备密钥重新加密为
///   `card_no_ciphertext`。
/// - 外层备份包本身仍然通过 Argon2id(password) → AES-GCM 包裹，保障即便 JSON
///   被拿到也不可读。
class DbSnapshotService implements DbSnapshotRepository {
  DbSnapshotService(this._db, this._crypto)
      : _dictEntryDao = _db.dictEntryDao;

  final AppDatabase _db;
  final CryptoService _crypto;
  final DictEntryDao _dictEntryDao;

  static const _cardBackupPlaintextField = 'cardNoBackup';

  Future<Map<String, dynamic>> _portableCard(Map<String, dynamic> json) async {
    final copy = Map<String, dynamic>.of(json);
    copy.remove('cvvCiphertext');
    final cardCt = copy['cardNoCiphertext'];
    if (cardCt is String && cardCt.isNotEmpty) {
      final clear = await _crypto.decryptField(
        purpose: CryptoPurpose.cardNo,
        ciphertext: cardCt,
      );
      if (clear.isErr) {
        throw StorageError('export: failed to decrypt card number for backup');
      }
      copy[_cardBackupPlaintextField] = clear.valueOrNull!;
    }
    copy.remove('cardNoCiphertext');
    return copy;
  }

  Future<Map<String, dynamic>> _restoreCard(Map<String, dynamic> json) async {
    final copy = Map<String, dynamic>.of(json);
    copy.remove('cvvCiphertext');
    final backupCardNo = copy.remove(_cardBackupPlaintextField);
    if (backupCardNo is String && backupCardNo.isNotEmpty) {
      final encrypted = await _crypto.encryptField(
        purpose: CryptoPurpose.cardNo,
        plaintext: backupCardNo,
      );
      if (encrypted.isErr) {
        throw StorageError('restore: failed to encrypt card number on target device');
      }
      copy['cardNoCiphertext'] = encrypted.valueOrNull!;
    } else {
      copy.remove('cardNoCiphertext');
    }
    return copy;
  }

  Map<String, dynamic> _restoreAccount(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.of(json);
    copy.putIfAbsent('fxSpreadPercent', () => 0.0);
    copy.putIfAbsent('fxFixedFee', () => '0');
    copy.putIfAbsent('isDeleted', () => false);
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
      'cards': await Future.wait(
        (await _db.select(_db.cards).get()).map((r) => _portableCard(r.toJson())),
      ),
      'channels': (await _db.select(_db.channels).get())
          .map((r) => r.toJson())
          .toList(),
      'dict_entries': (await _db.select(_db.dictEntries).get())
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
      'search_history_entries': (await _db.select(_db.searchHistoryEntries).get())
          .map((r) => r.toJson())
          .toList(),
    };
  }

  @override
  Future<String> exportJson() async {
    final buffer = StringBuffer()..write('{');
    var firstTable = true;

    Future<void> appendTable(
      String name,
      Future<List<Map<String, dynamic>>> Function() load,
    ) async {
      if (!firstTable) buffer.write(',');
      firstTable = false;
      buffer
        ..write(jsonEncode(name))
        ..write(':[');
      final rows = await load();
      for (var i = 0; i < rows.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write(jsonEncode(rows[i]));
      }
      buffer.write(']');
    }

    await appendTable(
      'accounts',
      () async => (await _db.select(_db.accounts).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'assets',
      () async => (await _db.select(_db.assets).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'asset_cost_history',
      () async => (await _db.select(_db.assetCostHistory).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'cards',
      () async => Future.wait(
        (await _db.select(_db.cards).get()).map((r) => _portableCard(r.toJson())),
      ),
    );
    await appendTable(
      'channels',
      () async => (await _db.select(_db.channels).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'dict_entries',
      () async => (await _db.select(_db.dictEntries).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'account_channels',
      () async => (await _db.select(_db.accountChannels).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'exchange_rates',
      () async => (await _db.select(_db.exchangeRates).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'events',
      () async => (await _db.select(_db.events).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'asset_price_history',
      () async => (await _db.select(_db.assetPriceHistory).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'watched_pairs',
      () async => (await _db.select(_db.watchedPairs).get())
          .map((r) => r.toJson())
          .toList(),
    );
    await appendTable(
      'search_history_entries',
      () async => (await _db.select(_db.searchHistoryEntries).get())
          .map((r) => r.toJson())
          .toList(),
    );

    buffer.write('}');
    return buffer.toString();
  }

  @override
  Map<String, int> summarize(Map<String, List<Map<String, dynamic>>> snap) {
    return {
      'accounts': (snap['accounts'] ?? const []).length,
      'assets': (snap['assets'] ?? const []).length,
      'cards': (snap['cards'] ?? const []).length,
      'events': (snap['events'] ?? const []).length,
      'channels': (snap['channels'] ?? const []).length,
      'exchange_rates': (snap['exchange_rates'] ?? const []).length,
      'watched_pairs': (snap['watched_pairs'] ?? const []).length,
    };
  }

  /// 以快照覆盖当前数据库；外键按 accounts → cards/assets，channels / rates 独立，
  /// events 与 asset_price_history 最后写入。
  @override
  Future<void> restore(Map<String, List<Map<String, dynamic>>> snap) async {
    final restoredAccounts = (snap['accounts'] ?? const [])
        .map(_restoreAccount)
        .toList(growable: false);
    final restoredCards = await Future.wait(
      (snap['cards'] ?? const []).map(_restoreCard),
    );
    await _db.transaction(() async {
      // 清空顺序：子 → 父（account_channels 依赖 accounts/channels）
      await _db.delete(_db.assetPriceHistory).go();
      await _db.delete(_db.assetCostHistory).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.watchedPairs).go();
      await _db.delete(_db.searchHistoryEntries).go();
      await _db.delete(_db.accountChannels).go();
      await _db.delete(_db.channels).go();
      await _db.delete(_db.dictEntries).go();
      await _db.delete(_db.cards).go();
      await _db.delete(_db.assets).go();
      await _db.delete(_db.accounts).go();

      await _batchInsert(
        _db.accounts,
        restoredAccounts,
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
        restoredCards,
        CardRow.fromJson,
      );
      await _batchInsert(
        _db.channels,
        snap['channels'] ?? const [],
        ChannelRow.fromJson,
      );
      await _batchInsert(
        _db.dictEntries,
        snap['dict_entries'] ?? const [],
        DictEntryRow.fromJson,
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
      await _batchInsert(
        _db.searchHistoryEntries,
        snap['search_history_entries'] ?? const [],
        SearchHistoryEntryRow.fromJson,
      );
    });
  }

  /// 在单个事务里清空用户数据（按 child → parent 顺序避免外键冲突）。
  ///
  /// 内置字典项由 migration 预置，reset 时保留；仅删除用户新增的自定义字典项。
  @override
  Future<void> truncateAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.assetPriceHistory).go();
      await _db.delete(_db.assetCostHistory).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.accountChannels).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.watchedPairs).go();
      await _db.delete(_db.searchHistoryEntries).go();
      await _dictEntryDao.deleteAllCustom();
      await _db.delete(_db.cards).go();
      await _db.delete(_db.assets).go();
      await _db.delete(_db.channels).go();
      await _db.delete(_db.accounts).go();
      await seedBuiltinChannels(_db);
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
