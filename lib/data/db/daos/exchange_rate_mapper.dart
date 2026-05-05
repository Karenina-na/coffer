import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/exchange_rate_enums.dart';
import '../database.dart';

class ExchangeRateMapper {
  const ExchangeRateMapper();

  ExchangeRate toDomain(ExchangeRateRow r) => ExchangeRate(
        id: r.id,
        pairKey: r.pairKey,
        baseCurrency: r.baseCurrency,
        quoteCurrency: r.quoteCurrency,
        rate: Money.parseOrNull(r.rate) ?? Decimal.zero,
        asOfTime: r.asOfTime,
        updatedAt: r.updatedAt,
        source: r.source,
        snapshotType: SnapshotType.fromCode(r.snapshotType),
        rawPayload: r.rawPayload,
      );

  ExchangeRatesCompanion toInsert(ExchangeRate e) =>
      ExchangeRatesCompanion.insert(
        id: e.id,
        pairKey: e.pairKey,
        baseCurrency: e.baseCurrency,
        quoteCurrency: e.quoteCurrency,
        rate: e.rate.toString(),
        asOfTime: normalizeAsOfTime(e.asOfTime, e.snapshotType),
        updatedAt: e.updatedAt,
        source: e.source,
        snapshotType: e.snapshotType.code,
        rawPayload:
            e.rawPayload == null ? const Value.absent() : Value(e.rawPayload!),
      );

  /// DAILY 快照按「日」去重：统一截断到 UTC 当日 00:00；
  /// HOURLY/REALTIME 保留原始时间戳，靠 (pair_key, as_of_time) 自然区分。
  static DateTime normalizeAsOfTime(DateTime t, SnapshotType type) {
    if (type != SnapshotType.daily) return t;
    final u = t.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }
}
