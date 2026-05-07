import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../../core/ui/gwp_node_map.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import '../../../domain/events/event_bus.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_providers.dart';
import '../../channel/presentation/channel_providers.dart';
import '../../event/presentation/event_providers.dart';
import '../../../data/providers/exchange_rate_providers.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.baseCurrency,
    required this.total,
    required this.accountCount,
    required this.assetCount,
    required this.missingAssetIds,
  });

  final String baseCurrency;
  final Decimal total;
  final int accountCount;
  final int assetCount;
  final List<String> missingAssetIds;
}

double computeCreditUsedRatio(Decimal limitSum, Decimal availSum) {
  if (limitSum <= Decimal.zero) return 0;
  final ratio = Money.ratio(availSum, limitSum);
  final used = Decimal.one - ratio;
  final usedDouble = used.toDouble();
  if (usedDouble.isNaN || usedDouble.isInfinite) return 0;
  return usedDouble.clamp(0, 1);
}

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final base = ref.watch(valuationCurrencyProvider);
  final accounts = await ref.watch(accountListProvider.future);
  final valued = await ref.watch(valuedAssetsProvider.future);

  return DashboardSummary(
      baseCurrency: base,
      total: valued.total,
      accountCount: accounts.length,
      assetCount: valued.assets.length,
      missingAssetIds: valued.missingAssetIds,
  );
});

class DashboardKpi {
  const DashboardKpi({
    required this.assetCount,
    required this.accountCount,
    required this.cardCount,
    required this.creditCardCount,
    required this.creditUsedRatio,
    required this.pendingEventCount,
    required this.criticalEventCount,
    required this.regionSet,
  });

  final int assetCount;
  final int accountCount;
  final int cardCount;
  final int creditCardCount;
  final double creditUsedRatio;
  final int pendingEventCount;
  final int criticalEventCount;
  final Set<String> regionSet;
}

final dashboardKpiProvider =
    FutureProvider.autoDispose<DashboardKpi>((ref) async {
  final valued = await ref.watch(valuedAssetsProvider.future);
  final accounts = await ref.watch(accountListProvider.future);
  final cards = await ref.watch(cardListProvider.future);
  final pendingEvents = await ref.watch(pendingAckEventsProvider.future);

  final creditCards = cards
      .where((card) => card.cardType == CardType.credit)
      .toList(growable: false);
  final limitSum = creditCards.fold<Decimal>(
    Decimal.zero,
    (sum, card) => sum + (card.creditLimit ?? Decimal.zero),
  );
  final availSum = creditCards.fold<Decimal>(
    Decimal.zero,
    (sum, card) => sum + (card.availableCredit ?? Decimal.zero),
  );
  final criticalEventCount = pendingEvents
      .where((event) => event.priority == EventPriority.critical)
      .length;

  return DashboardKpi(
    assetCount: valued.assets.length,
    accountCount: accounts.length,
    cardCount: cards.length,
    creditCardCount: creditCards.length,
    creditUsedRatio: computeCreditUsedRatio(limitSum, availSum),
    pendingEventCount: pendingEvents.length,
    criticalEventCount: criticalEventCount,
    regionSet: accounts.map((account) => account.sovereigntyRegion).toSet(),
  );
});

class AllocationSlice {
  const AllocationSlice({
    required this.key,
    required this.value,
  });

  final String key;
  final double value;
}

List<AllocationSlice> _toSortedSlices(Map<String, Decimal> bucket) {
  return bucket.entries
      .map(
        (entry) => AllocationSlice(
          key: entry.key,
          value: entry.value.toDouble(),
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));
}

final allocationByCurrencyProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final valued = await ref.watch(valuedAssetsProvider.future);
  final bucket = <String, Decimal>{};
  for (final item in valued.assets) {
    final marketValue = item.valuedAmount;
    if (marketValue == null) continue;
    bucket[item.asset.currency] =
        (bucket[item.asset.currency] ?? Decimal.zero) + marketValue;
  }
  return _toSortedSlices(bucket);
});

final allocationByTypeProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final valued = await ref.watch(valuedAssetsProvider.future);
  final bucket = <String, Decimal>{};
  for (final item in valued.assets) {
    final marketValue = item.valuedAmount;
    if (marketValue == null) continue;
    final key = item.asset.assetType.name;
    bucket[key] = (bucket[key] ?? Decimal.zero) + marketValue;
  }
  return _toSortedSlices(bucket);
});

final allocationByRegionProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final valued = await ref.watch(valuedAssetsProvider.future);
  final accounts = await ref.watch(accountListProvider.future);
  final accountById = {for (final account in accounts) account.id: account};
  final bucket = <String, Decimal>{};
  for (final item in valued.assets) {
    final marketValue = item.valuedAmount;
    if (marketValue == null) continue;
    final region =
        accountById[item.asset.accountId]?.sovereigntyRegion ?? 'UNKNOWN';
    bucket[region] = (bucket[region] ?? Decimal.zero) + marketValue;
  }
  return _toSortedSlices(bucket);
});

class NodeMapData {
  const NodeMapData({
    required this.nodes,
    required this.edges,
  });

  final List<MapNode> nodes;
  final List<MapEdge> edges;
}

final nodeMapDataProvider = FutureProvider.autoDispose<NodeMapData>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final valued = await ref.watch(valuedAssetsProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final accountChannels = await ref.watch(accountChannelListProvider.future);

  final assetTotalsByAccount = <String, Decimal>{};
  for (final item in valued.assets) {
    final marketValue = item.valuedAmount;
    if (marketValue == null) continue;
    assetTotalsByAccount[item.asset.accountId] =
        (assetTotalsByAccount[item.asset.accountId] ?? Decimal.zero) + marketValue;
  }

  final regionTotals = <String, Decimal>{};
  final regionAccountCounts = <String, int>{};
  final regionByAccountId = <String, String>{};
  for (final account in accounts) {
    final region = account.sovereigntyRegion;
    regionByAccountId[account.id] = region;
    regionTotals[region] = (regionTotals[region] ?? Decimal.zero) +
        (assetTotalsByAccount[account.id] ?? Decimal.zero);
    regionAccountCounts[region] = (regionAccountCounts[region] ?? 0) + 1;
  }

  final nodes = regionTotals.entries
      .map(
        (entry) => MapNode(
          regionCode: entry.key,
          label: entry.value.toString(),
          value: entry.value.toDouble(),
          accountCount: regionAccountCounts[entry.key] ?? 0,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));

  final activeChannelIds = channels.map((channel) => channel.id).toSet();
  final accountsByChannel = <String, Set<String>>{};
  for (final link in accountChannels) {
    if (!activeChannelIds.contains(link.channelId)) continue;
    (accountsByChannel[link.channelId] ??= <String>{}).add(link.accountId);
  }

  final edgeCounts = <(String, String), int>{};
  for (final accountIds in accountsByChannel.values) {
    final regions = accountIds
        .map((accountId) => regionByAccountId[accountId])
        .whereType<String>()
        .toSet()
        .toList(growable: false)
      ..sort();
    for (var i = 0; i < regions.length; i++) {
      for (var j = i + 1; j < regions.length; j++) {
        final key = (regions[i], regions[j]);
        edgeCounts[key] = (edgeCounts[key] ?? 0) + 1;
      }
    }
  }

  final edges = edgeCounts.entries
      .map(
        (entry) => MapEdge(
          fromRegion: entry.key.$1,
          toRegion: entry.key.$2,
          channelCount: entry.value,
        ),
      )
      .toList(growable: false);

  return NodeMapData(nodes: nodes, edges: edges);
});

enum BillKind { statementDay, paymentDue }

class UpcomingBill {
  const UpcomingBill({
    required this.card,
    required this.kind,
    required this.daysFromNow,
    required this.date,
  });

  final BankCard card;
  final BillKind kind;
  final int daysFromNow;
  final DateTime date;
}

DateTime? _nextDateForDay(int? day, DateTime now) {
  if (day == null || day <= 0) return null;
  final clampedThisMonth = day.clamp(1, _daysInMonth(now.year, now.month));
  var candidate = DateTime(now.year, now.month, clampedThisMonth);
  if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final clampedNextMonth = day.clamp(1, _daysInMonth(nextYear, nextMonth));
    candidate = DateTime(nextYear, nextMonth, clampedNextMonth);
  }
  return candidate;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

int _daysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

final upcomingBillsProvider =
    FutureProvider.autoDispose<List<UpcomingBill>>((ref) async {
  final cards = await ref.watch(cardListProvider.future);
  final now = DateTime.now();
  final bills = <UpcomingBill>[];

  for (final card in cards.where((card) => card.cardType == CardType.credit)) {
    final paymentDate = _nextDateForDay(card.paymentDueDay, now);
    if (paymentDate != null) {
      final days = _daysBetween(now, paymentDate);
      if (days <= 30) {
        bills.add(
          UpcomingBill(
            card: card,
            kind: BillKind.paymentDue,
            daysFromNow: days,
            date: paymentDate,
          ),
        );
      }
    }

    final statementDate = _nextDateForDay(card.billingCycleDay, now);
    if (statementDate != null) {
      final days = _daysBetween(now, statementDate);
      if (days <= 30) {
        bills.add(
          UpcomingBill(
            card: card,
            kind: BillKind.statementDay,
            daysFromNow: days,
            date: statementDate,
          ),
        );
      }
    }
  }

  bills.sort((a, b) => a.date.compareTo(b.date));
  return bills;
});

final recentActivitiesProvider =
    FutureProvider.autoDispose<List<DomainEvent>>((ref) async {
  final events = await ref.watch(recentEventsProvider.future);
  return [...events]
    ..sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
});

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
  return all.where((point) => !point.date.isBefore(since)).toList(growable: false);
}

final netWorthTrendProvider =
    FutureProvider.autoDispose<List<TrendPoint>>((ref) async {
  final range = ref.watch(trendRangeProvider);
  final base = ref.watch(valuationCurrencyProvider);
  final history = await ref.watch(assetPriceHistoryRepositoryProvider).listForTrend(
        since: _sinceForRange(range),
      );
  final summary = await ref.watch(dashboardSummaryProvider.future);

  // Collect asset → currency mapping from history.
  final assetCurrency = <String, String>{};
  for (final p in history) {
    assetCurrency[p.assetId] = p.currency.toUpperCase();
  }

  // If all assets share the base currency, skip FX conversion.
  final needsConversion =
      assetCurrency.values.any((c) => c != base);
  if (!needsConversion) {
    return buildTrendPoints(history: history, currentTotal: summary.total);
  }

  // Per-day conversion: carry-forward per-asset values (converted to base).
  final rateRepo = ref.watch(exchangeRateRepositoryProvider);
  final sortedDays = <DateTime>[];
  final sortedDaysSet = <DateTime>{};
  final perDayConverted = <DateTime, Map<String, Decimal>>{};

  for (final p in history) {
    final marketValue = p.marketValue;
    if (marketValue == null) continue;
    final day = DateTime(p.triggerTime.year, p.triggerTime.month, p.triggerTime.day);
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

final trendRangeProvider =
    NotifierProvider<TrendRangeNotifier, int>(TrendRangeNotifier.new);

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

final accountNetWorthTrendProvider =
    FutureProvider.autoDispose.family<List<TrendPoint>, String>((
  ref,
  accountId,
) async {
  final assets = await ref.watch(assetsByAccountProvider(accountId).future);
  final valuedAssets = await ref.watch(valuedAssetsByAccountProvider(accountId).future);
  final assetIds = assets.map((asset) => asset.id).toSet();
  if (assetIds.isEmpty) return const [];

  final range = ref.watch(trendRangeProvider);
  final base = ref.watch(valuationCurrencyProvider);
  final history = await ref.watch(assetPriceHistoryRepositoryProvider).listForTrend(
        since: _sinceForRange(range),
        assetIds: assetIds,
      );

  // Collect asset → currency mapping.
  final assetCurrency = <String, String>{};
  for (final p in history) {
    assetCurrency[p.assetId] = p.currency.toUpperCase();
  }

  final currentTotal = valuedAssets.total;

  // If all assets share the base currency, skip FX conversion.
  final needsConversion =
      assetCurrency.values.any((c) => c != base);
  if (!needsConversion) {
    return buildTrendPoints(history: history, currentTotal: currentTotal);
  }

  // Per-day conversion with carry-forward.
  final rateRepo = ref.watch(exchangeRateRepositoryProvider);
  final sortedDays = <DateTime>[];
  final sortedDaysSet = <DateTime>{};
  final perDayConverted = <DateTime, Map<String, Decimal>>{};

  for (final p in history) {
    final marketValue = p.marketValue;
    if (marketValue == null) continue;
    final day = DateTime(p.triggerTime.year, p.triggerTime.month, p.triggerTime.day);
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

final accountTrendDeltaProvider =
    FutureProvider.autoDispose.family<TrendDelta, (String, int)>((
  ref,
  args,
) async {
  final (accountId, range) = args;
  final all = await ref.watch(accountNetWorthTrendProvider(accountId).future);
  return _buildTrendDelta(_pointsForRange(all, range));
});

final todaysRateAlertsProvider =
    FutureProvider.autoDispose<List<DomainEvent>>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final events = await ref.watch(recentEventsProvider.future);
  final todays = events
      .where(
        (event) =>
            event.eventType == DomainEventTypes.rateAlert &&
            !event.triggerTime.isBefore(startOfDay),
      )
      .toList(growable: false)
    ..sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
  return todays;
});
