import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/watched_pair.dart';
import '../../domain/repositories/watched_pair_repository.dart';
import '../../domain/utils/pair_key.dart';
import '../db/database.dart';
import '../db/daos/watched_pair_dao.dart';

Decimal? _parseDec(String? s) => s == null ? null : Decimal.tryParse(s);

class DriftWatchedPairRepository implements WatchedPairRepository {
  DriftWatchedPairRepository(this._dao);

  final WatchedPairDao _dao;

  WatchedPair _toDomain(WatchedPairRow r) => WatchedPair(
        pairKey: r.pairKey,
        baseCurrency: r.baseCurrency,
        quoteCurrency: r.quoteCurrency,
        createdAt: r.createdAt,
        sortOrder: r.sortOrder,
        thresholdHigh: _parseDec(r.thresholdHigh),
        thresholdLow: _parseDec(r.thresholdLow),
        alertChangePct: _parseDec(r.alertChangePct),
      );
  // Note: freezed-generated copyWith now provides proper structural equality
  // and full field support (including null-safe unset of optional fields).

  @override
  Stream<List<WatchedPair>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList(growable: false));

  @override
  Future<List<WatchedPair>> listAll() async {
    final rows = await _dao.listAll();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<Result<WatchedPair, AppError>> add({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final quote = quoteCurrency.trim().toUpperCase();
    if (base.isEmpty || quote.isEmpty) {
      return const Err(ValidationError('币种不能为空'));
    }
    if (base == quote) {
      return const Err(ValidationError('基准与报价不能相同'));
    }
    try {
      final now = DateTime.now();
      final key = pairKeyOf(base, quote);
      final all = await _dao.listAll();
      final nextSortOrder = all.isEmpty ? 100 : (all.last.sortOrder + 10);
      await _dao.upsert(WatchedPairsCompanion.insert(
        pairKey: key,
        baseCurrency: base,
        quoteCurrency: quote,
        createdAt: now,
        sortOrder: Value(nextSortOrder),
      ));
      return Ok(WatchedPair(
        pairKey: key,
        baseCurrency: base,
        quoteCurrency: quote,
        createdAt: now,
        sortOrder: nextSortOrder,
      ));
    } catch (e) {
      return Err(StorageError('add watched pair failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> remove(String pairKey) async {
    final key = pairKey.trim().toUpperCase();
    try {
      final db = _dao.attachedDatabase;
      await db.transaction(() async {
        await (db.delete(db.exchangeRates)..where((t) => t.pairKey.equals(key))).go();
        await _dao.deleteByKey(key);
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('remove watched pair failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateThresholds({
    required String pairKey,
    required Decimal? thresholdHigh,
    required Decimal? thresholdLow,
    required Decimal? alertChangePct,
  }) async {
    if (alertChangePct != null && alertChangePct <= Decimal.zero) {
      return const Err(ValidationError('波动阈值需为正数'));
    }
    if (thresholdHigh != null && thresholdLow != null &&
        thresholdHigh <= thresholdLow) {
      return const Err(ValidationError('上沿必须大于下沿'));
    }
    try {
      final n = await _dao.updateThresholds(
        pairKey: pairKey,
        thresholdHigh: thresholdHigh?.toString(),
        thresholdLow: thresholdLow?.toString(),
        alertChangePct: alertChangePct?.toString(),
      );
      if (n == 0) {
        return const Err(NotFoundError('watched pair not found'));
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('update thresholds failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> reorder(List<String> pairKeys) async {
    try {
      final normalized = pairKeys.map((e) => e.trim().toUpperCase()).toList(growable: false);
      for (var i = 0; i < normalized.length; i++) {
        await _dao.updateSortOrder(normalized[i], 100 + i * 10);
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('reorder watched pairs failed: $e'));
    }
  }
}
