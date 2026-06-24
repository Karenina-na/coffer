import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/region_meta.dart';
import '../../../core/ui/coffer_node_map.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_providers.dart';
import '../../channel/presentation/channel_providers.dart';
import '../../event/presentation/event_providers.dart';
import '../../../data/providers/dict_providers.dart';

double computeCreditUsedRatio(Decimal limitSum, Decimal availSum) {
  if (limitSum <= Decimal.zero) return 0;
  final ratio = Money.ratio(availSum, limitSum);
  final used = Decimal.one - ratio;
  final usedDouble = used.toDouble();
  if (usedDouble.isNaN || usedDouble.isInfinite) return 0;
  return usedDouble.clamp(0, 1);
}

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

final dashboardKpiProvider = FutureProvider.autoDispose<DashboardKpi>((
  ref,
) async {
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
  const AllocationSlice({required this.key, required this.value});

  final String key;
  final double value;
}

List<AllocationSlice> _toSortedSlices(Map<String, Decimal> bucket) {
  return bucket.entries
      .map(
        (entry) =>
            AllocationSlice(key: entry.key, value: entry.value.toDouble()),
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

final allocationByRegionAggregateProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
      final valued = await ref.watch(valuedAssetsProvider.future);
      final accounts = await ref.watch(accountListProvider.future);
      final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
      final accountById = {for (final account in accounts) account.id: account};
      final bucket = <String, Decimal>{};
      for (final item in valued.assets) {
        final marketValue = item.valuedAmount;
        if (marketValue == null) continue;
        final region =
            accountById[item.asset.accountId]?.sovereigntyRegion ?? 'UNKNOWN';
        final aggregate = regionAggregateKey(regionIndex, region);
        bucket[aggregate] = (bucket[aggregate] ?? Decimal.zero) + marketValue;
      }
      return _toSortedSlices(bucket);
    });

class NodeMapData {
  const NodeMapData({required this.nodes, required this.edges});

  final List<MapNode> nodes;
  final List<MapEdge> edges;
}

Future<NodeMapData> _buildNodeMapData(
  Ref ref, {
  required bool aggregateParents,
}) async {
  final accounts = await ref.watch(accountListProvider.future);
  final valued = await ref.watch(valuedAssetsProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final accountChannels = await ref.watch(accountChannelListProvider.future);
  final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};

  final assetTotalsByAccount = <String, Decimal>{};
  for (final item in valued.assets) {
    final marketValue = item.valuedAmount;
    if (marketValue == null) continue;
    assetTotalsByAccount[item.asset.accountId] =
        (assetTotalsByAccount[item.asset.accountId] ?? Decimal.zero) +
        marketValue;
  }

  final regionTotals = <String, Decimal>{};
  final regionAccountCounts = <String, int>{};
  final regionByAccountId = <String, String>{};
  for (final account in accounts) {
    final region = aggregateParents
        ? regionAggregateKey(regionIndex, account.sovereigntyRegion)
        : account.sovereigntyRegion;
    regionByAccountId[account.id] = region;
    regionTotals[region] =
        (regionTotals[region] ?? Decimal.zero) +
        (assetTotalsByAccount[account.id] ?? Decimal.zero);
    regionAccountCounts[region] = (regionAccountCounts[region] ?? 0) + 1;
  }

  final nodes =
      regionTotals.entries
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
    final regions =
        accountIds
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
}

final nodeMapDataProvider = FutureProvider.autoDispose<NodeMapData>((ref) {
  return _buildNodeMapData(ref, aggregateParents: false);
});

final nodeMapAggregateDataProvider = FutureProvider.autoDispose<NodeMapData>((
  ref,
) {
  return _buildNodeMapData(ref, aggregateParents: true);
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

final upcomingBillsProvider = FutureProvider.autoDispose<List<UpcomingBill>>((
  ref,
) async {
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

final recentActivitiesProvider = FutureProvider.autoDispose<List<DomainEvent>>((
  ref,
) async {
  final events = await ref.watch(recentEventsProvider.future);
  return [...events]..sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
});
