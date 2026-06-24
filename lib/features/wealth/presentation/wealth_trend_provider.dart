import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/exchange_rate_providers.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/events/event_bus.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../event/presentation/event_providers.dart';
import 'wealth_summary_provider.dart';

class TrendPoint {
  const TrendPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

List<TrendPoint> buildTrendPoints({
  required Iterable<AssetPriceHistoryPoint> history,
  required Decimal currentTotal,
}) {
  final perDayAsset = <DateTime, Map<String, Decimal>>{};
  final allDays = <DateTime>{};

  for (final point in history) {
    final day = DateTime(
      point.triggerTime.year,
      point.triggerTime.month,
      point.triggerTime.day,
    );
    final marketValue = point.marketValue;
    if (marketValue == null) continue;
    (perDayAsset[day] ??= {})[point.assetId] = marketValue;
    allDays.add(day);
  }

  final points = <TrendPoint>[];
  if (allDays.isNotEmpty) {
    final sortedDays = allDays.toList()..sort();
    final carry = <String, Decimal>{};
    for (final day in sortedDays) {
      carry.addAll(perDayAsset[day]!);
      final total = carry.values.fold<Decimal>(
        Decimal.zero,
        (sum, value) => sum + value,
      );
      points.add(TrendPoint(day, total.toDouble()));
    }
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentValue = currentTotal.toDouble();
  if (points.isEmpty || points.last.date != today) {
    points.add(TrendPoint(today, currentValue));
  } else {
    points[points.length - 1] = TrendPoint(today, currentValue);
  }
  return points;
}

DateTime? _sinceForRange(int rangeDays) {
  if (rangeDays == 0) return null;
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  return day.subtract(Duration(days: rangeDays));
}

List<TrendPoint> _pointsForRange(List<TrendPoint> all, int rangeDays) {
  if (rangeDays == 0) return all;
  final since = _sinceForRange(rangeDays)!;
  return all
      .where((point) => !point.date.isBefore(since))
      .toList(growable: false);
}

final trendRangeProvider = NotifierProvider<TrendRangeNotifier, int>(
  TrendRangeNotifier.new,
);

final netWorthTrendProvider = FutureProvider.autoDispose<List<TrendPoint>>((
  ref,
) async {
  final range = ref.watch(trendRangeProvider);
  final base = ref.watch(valuationCurrencyProvider);
  final history = await ref
      .watch(assetPriceHistoryRepositoryProvider)
      .listForTrend(since: _sinceForRange(range));
  final summary = await ref.watch(wealthSummaryProvider.future);

  final assetCurrency = <String, String>{};
  for (final p in history) {
    assetCurrency[p.assetId] = p.currency.toUpperCase();
  }

  final needsConversion = assetCurrency.values.any((c) => c != base);
  if (!needsConversion) {
    return buildTrendPoints(history: history, currentTotal: summary.total);
  }

  final rateRepo = ref.watch(exchangeRateRepositoryProvider);
  final sortedDays = <DateTime>[];
  final sortedDaysSet = <DateTime>{};
  final perDayConverted = <DateTime, Map<String, Decimal>>{};

  for (final p in history) {
    final marketValue = p.marketValue;
    if (marketValue == null) continue;
    final day = DateTime(
      p.triggerTime.year,
      p.triggerTime.month,
      p.triggerTime.day,
    );
    final ccy = p.currency.toUpperCase();
    var valueInBase = marketValue;
    if (ccy != base) {
      final rate = await rateRepo.latestFor(
        baseCurrency: ccy,
        quoteCurrency: base,
      );
      if (rate.isOk && rate.valueOrNull!.rate > Decimal.zero) {
        valueInBase = marketValue * rate.valueOrNull!.rate;
      } else {
        continue;
      }
    }
    (perDayConverted[day] ??= {})[p.assetId] = valueInBase;
    if (sortedDaysSet.add(day)) sortedDays.add(day);
  }
  sortedDays.sort();

  final points = <TrendPoint>[];
  if (sortedDays.isNotEmpty) {
    final carry = <String, Decimal>{};
    for (final day in sortedDays) {
      carry.addAll(perDayConverted[day]!);
      final total = carry.values.fold<Decimal>(
        Decimal.zero,
        (sum, value) => sum + value,
      );
      points.add(TrendPoint(day, total.toDouble()));
    }
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentValue = summary.total.toDouble();
  if (points.isEmpty || points.last.date != today) {
    points.add(TrendPoint(today, currentValue));
  } else {
    points[points.length - 1] = TrendPoint(today, currentValue);
  }
  return points;
});

class TrendRangeNotifier extends Notifier<int> {
  @override
  int build() => 30;

  void set(int value) => state = value;
}

class TrendDelta {
  const TrendDelta({
    required this.points,
    required this.startValue,
    required this.endValue,
    required this.minValue,
    required this.maxValue,
  });

  final List<TrendPoint> points;
  final double startValue;
  final double endValue;
  final double minValue;
  final double maxValue;

  double get deltaAbs => endValue - startValue;
  double get deltaPct =>
      startValue == 0 ? 0 : (endValue - startValue) / startValue;
  bool get isUp => deltaAbs >= 0;
  bool get hasEnoughData => points.length >= 2;
}

TrendDelta _buildTrendDelta(List<TrendPoint> points) {
  if (points.isEmpty) {
    return const TrendDelta(
      points: [],
      startValue: 0,
      endValue: 0,
      minValue: 0,
      maxValue: 0,
    );
  }

  var minValue = points.first.value;
  var maxValue = points.first.value;
  for (final point in points) {
    if (point.value < minValue) minValue = point.value;
    if (point.value > maxValue) maxValue = point.value;
  }

  return TrendDelta(
    points: points,
    startValue: points.first.value,
    endValue: points.last.value,
    minValue: minValue,
    maxValue: maxValue,
  );
}

final trendDeltaProvider = FutureProvider.autoDispose<TrendDelta>((ref) async {
  final all = await ref.watch(netWorthTrendProvider.future);
  final range = ref.watch(trendRangeProvider);
  return _buildTrendDelta(_pointsForRange(all, range));
});

final accountNetWorthTrendProvider = FutureProvider.autoDispose
    .family<List<TrendPoint>, String>((ref, accountId) async {
      final assets = await ref.watch(assetsByAccountProvider(accountId).future);
      final valuedAssets = await ref.watch(
        valuedAssetsByAccountProvider(accountId).future,
      );
      final assetIds = assets.map((asset) => asset.id).toSet();
      if (assetIds.isEmpty) return const [];

      final range = ref.watch(trendRangeProvider);
      final base = ref.watch(valuationCurrencyProvider);
      final history = await ref
          .watch(assetPriceHistoryRepositoryProvider)
          .listForTrend(since: _sinceForRange(range), assetIds: assetIds);

      final assetCurrency = <String, String>{};
      for (final p in history) {
        assetCurrency[p.assetId] = p.currency.toUpperCase();
      }

      final currentTotal = valuedAssets.total;

      final needsConversion = assetCurrency.values.any((c) => c != base);
      if (!needsConversion) {
        return buildTrendPoints(history: history, currentTotal: currentTotal);
      }

      final rateRepo = ref.watch(exchangeRateRepositoryProvider);
      final sortedDays = <DateTime>[];
      final sortedDaysSet = <DateTime>{};
      final perDayConverted = <DateTime, Map<String, Decimal>>{};

      for (final p in history) {
        final marketValue = p.marketValue;
        if (marketValue == null) continue;
        final day = DateTime(
          p.triggerTime.year,
          p.triggerTime.month,
          p.triggerTime.day,
        );
        final ccy = p.currency.toUpperCase();
        var valueInBase = marketValue;
        if (ccy != base) {
          final rate = await rateRepo.latestFor(
            baseCurrency: ccy,
            quoteCurrency: base,
          );
          if (rate.isOk && rate.valueOrNull!.rate > Decimal.zero) {
            valueInBase = marketValue * rate.valueOrNull!.rate;
          } else {
            continue;
          }
        }
        (perDayConverted[day] ??= {})[p.assetId] = valueInBase;
        if (sortedDaysSet.add(day)) sortedDays.add(day);
      }
      sortedDays.sort();

      final points = <TrendPoint>[];
      if (sortedDays.isNotEmpty) {
        final carry = <String, Decimal>{};
        for (final day in sortedDays) {
          carry.addAll(perDayConverted[day]!);
          final total = carry.values.fold<Decimal>(
            Decimal.zero,
            (sum, value) => sum + value,
          );
          points.add(TrendPoint(day, total.toDouble()));
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentValue = currentTotal.toDouble();
      if (points.isEmpty || points.last.date != today) {
        points.add(TrendPoint(today, currentValue));
      } else {
        points[points.length - 1] = TrendPoint(today, currentValue);
      }
      return points;
    });

final accountTrendDeltaProvider = FutureProvider.autoDispose
    .family<TrendDelta, (String, int)>((ref, args) async {
      final (accountId, range) = args;
      final all = await ref.watch(
        accountNetWorthTrendProvider(accountId).future,
      );
      return _buildTrendDelta(_pointsForRange(all, range));
    });

final todaysRateAlertsProvider = FutureProvider.autoDispose<List<DomainEvent>>((
  ref,
) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final events = await ref.watch(recentEventsProvider.future);
  final todays =
      events
          .where(
            (event) =>
                event.eventType == DomainEventTypes.rateAlert &&
                !event.triggerTime.isBefore(startOfDay),
          )
          .toList(growable: false)
        ..sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
  return todays;
});
