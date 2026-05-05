import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/exchange_rates.dart';

part 'exchange_rate_dao.g.dart';

@DriftAccessor(tables: [ExchangeRates])
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  Stream<List<ExchangeRateRow>> watchAll({int limit = 200}) {
    return (select(exchangeRates)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.asOfTime, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Future<ExchangeRateRow?> latestForPair(String pairKey) {
    return (select(exchangeRates)
          ..where((t) => t.pairKey.equals(pairKey))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.asOfTime, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 返回某币对在 [since] 之后的所有快照，按 asOfTime 升序（便于画折线）。
  Stream<List<ExchangeRateRow>> watchSeriesForPair({
    required String pairKey,
    required DateTime since,
  }) {
    return (select(exchangeRates)
          ..where((t) =>
              t.pairKey.equals(pairKey) &
              t.asOfTime.isBiggerOrEqualValue(since))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.asOfTime, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// 返回某币对在 [date] 当天（精确到 UTC 日）最近一条快照；无则返回 null。
  Future<ExchangeRateRow?> queryForDate(String pairKey, DateTime date) {
    // 取当天起始（UTC 00:00）和次日起始作为窗口，找该窗口内最新一条。
    final dayStart = DateTime.utc(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(exchangeRates)
          ..where((t) =>
              t.pairKey.equals(pairKey) &
              t.asOfTime.isBiggerOrEqualValue(dayStart) &
              t.asOfTime.isSmallerThanValue(dayEnd))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.asOfTime, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsert(ExchangeRatesCompanion row) async {
    // 唯一键是 (pair_key, as_of_time)（v6 新增索引）。
    // 同一币对同一天若已有快照，则整体替换，确保曲线每天只有一条点位。
    await into(exchangeRates).insert(
      row,
      onConflict: DoUpdate(
        (_) => row,
        target: [exchangeRates.pairKey, exchangeRates.asOfTime],
      ),
    );
  }
}
