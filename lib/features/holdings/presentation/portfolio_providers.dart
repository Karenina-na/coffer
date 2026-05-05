import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/gwp_bar_rank.dart';
import '../../../core/ui/gwp_radar_chart.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../channel/presentation/channel_providers.dart';
import '../../dashboard/presentation/dashboard_providers.dart';

// ──────────────────────────────────────────────────────────────
// Portfolio snapshot (hero card)
// ──────────────────────────────────────────────────────────────

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.netWorth,
    required this.baseCurrency,
    required this.accountCount,
    required this.assetCount,
    required this.currencyCount,
    required this.regionCount,
    required this.institutionCount,
    required this.missingRateCount,
  });

  final Decimal netWorth;
  final String baseCurrency;
  final int accountCount;
  final int assetCount;
  final int currencyCount;
  final int regionCount;
  final int institutionCount;
  final int missingRateCount;
}

final portfolioSnapshotProvider =
    FutureProvider.autoDispose<PortfolioSnapshot>((ref) async {
  final summary = await ref.watch(dashboardSummaryProvider.future);
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);

  final currencies = assets.map((a) => a.currency).toSet();
  final regions = accounts.map((a) => a.sovereigntyRegion).toSet();
  final institutions = accounts.map((a) => a.institutionName).toSet();

  return PortfolioSnapshot(
    netWorth: summary.total,
    baseCurrency: summary.baseCurrency,
    accountCount: accounts.length,
    assetCount: assets.length,
    currencyCount: currencies.length,
    regionCount: regions.length,
    institutionCount: institutions.length,
    missingRateCount: summary.missingAssetIds.length,
  );
});

// ──────────────────────────────────────────────────────────────
// Allocation slices (shared model for donut triptych & explorer)
// ──────────────────────────────────────────────────────────────

class AllocationSlice {
  const AllocationSlice({
    required this.label,
    required this.value,
    required this.percentage,
  });

  final String label;
  final double value; // display-only
  final double percentage; // 0-100
}

List<AllocationSlice> _groupAndSlice(
  List<Asset> assets,
  String Function(Asset) keyFn,
) {
  final totals = <String, double>{};
  var grand = 0.0;
  for (final a in assets) {
    final mv = a.marketValue;
    if (mv == null || mv <= Decimal.zero) continue;
    final key = keyFn(a);
    final d = mv.toDouble();
    totals[key] = (totals[key] ?? 0) + d;
    grand += d;
  }
  if (grand <= 0) return [];
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => AllocationSlice(
            label: e.key,
            value: e.value,
            percentage: e.value / grand * 100,
          ))
      .toList();
}

/// Asset allocation grouped by asset type.
final portfolioByTypeProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final assets = await ref.watch(assetListProvider.future);
  return _groupAndSlice(assets, (a) => a.assetType.name);
});

/// Asset allocation grouped by currency.
final portfolioByCurrencyProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final assets = await ref.watch(assetListProvider.future);
  return _groupAndSlice(assets, (a) => a.currency);
});

/// Asset allocation grouped by sovereignty region (via account join).
final portfolioByRegionProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final map = {for (final a in accounts) a.id: a.sovereigntyRegion};
  return _groupAndSlice(assets, (a) => map[a.accountId] ?? '未知');
});

/// Asset allocation grouped by institution (via account join).
final portfolioByInstitutionProvider =
    FutureProvider.autoDispose<List<AllocationSlice>>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final map = {for (final a in accounts) a.id: a.institutionName};
  return _groupAndSlice(assets, (a) => map[a.accountId] ?? '未知');
});

// ──────────────────────────────────────────────────────────────
// Asset Top 10 ranking
// ──────────────────────────────────────────────────────────────

/// Top 10 assets by market value, for the horizontal bar chart.
final assetTop10Provider =
    FutureProvider.autoDispose<List<RankItem>>((ref) async {
  final assets = await ref.watch(assetListProvider.future);

  final ranked = assets
      .where((a) => a.marketValue != null && a.marketValue! > Decimal.zero)
      .toList()
    ..sort((a, b) => b.marketValue!.compareTo(a.marketValue!));

  return ranked.take(10).map((a) {
    return RankItem(
      label: a.assetCode ?? (a.id.length >= 6 ? a.id.substring(0, 6) : a.id),
      value: a.marketValue!.toDouble(),
    );
  }).toList();
});

// ──────────────────────────────────────────────────────────────
// Per-account stacked bar data
// ──────────────────────────────────────────────────────────────

class StackedBarGroup {
  const StackedBarGroup({required this.label, required this.segments});
  final String label;
  final List<StackedSegment> segments;
}

class StackedSegment {
  const StackedSegment({required this.key, required this.value, this.color});
  final String key;
  final double value;
  final int? color;
}

/// Per-account asset composition for the stacked bar chart.
final accountStackedProvider =
    FutureProvider.autoDispose<List<StackedBarGroup>>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);

  final accountAssets = <String, Map<String, double>>{};
  for (final asset in assets) {
    final mv = asset.marketValue;
    if (mv == null || mv <= Decimal.zero) continue;
    final typeName = asset.assetType.name;
    accountAssets
        .putIfAbsent(asset.accountId, () => {})
        .update(typeName, (v) => v + mv.toDouble(), ifAbsent: () => mv.toDouble());
  }

  final accountMap = {for (final a in accounts) a.id: a};
  final groups = <StackedBarGroup>[];
  for (final entry in accountAssets.entries) {
    final account = accountMap[entry.key];
    if (account == null) continue;
    final segs = entry.value.entries
        .map((e) => StackedSegment(key: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    groups.add(StackedBarGroup(
      label: account.institutionName,
      segments: segs,
    ));
  }
  groups.sort((a, b) {
    final aTotal = a.segments.fold<double>(0, (s, seg) => s + seg.value);
    final bTotal = b.segments.fold<double>(0, (s, seg) => s + seg.value);
    return bTotal.compareTo(aTotal);
  });
  return groups;
});

// ──────────────────────────────────────────────────────────────
// Currency exposure heat matrix
// ──────────────────────────────────────────────────────────────

class HeatMatrixData {
  const HeatMatrixData({
    required this.accounts,
    required this.currencies,
    required this.cells,
    required this.maxValue,
  });
  final List<String> accounts;
  final List<String> currencies;
  final Map<(String, String), double> cells;
  final double maxValue;
}

/// Currency exposure matrix: accounts × currencies.
final currencyExposureProvider =
    FutureProvider.autoDispose<HeatMatrixData>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);

  final accountMap = {for (final a in accounts) a.id: a.institutionName};
  final cells = <(String, String), double>{};
  final accountNames = <String>{};
  final currencies = <String>{};

  for (final asset in assets) {
    final mv = asset.marketValue;
    if (mv == null || mv <= Decimal.zero) continue;
    final name = accountMap[asset.accountId] ?? '未知';
    accountNames.add(name);
    currencies.add(asset.currency);
    final key = (name, asset.currency);
    cells[key] = (cells[key] ?? 0) + mv.toDouble();
  }

  final maxVal = cells.values.fold<double>(0, (p, v) => v > p ? v : p);

  return HeatMatrixData(
    accounts: accountNames.toList()..sort(),
    currencies: currencies.toList()..sort(),
    cells: cells,
    maxValue: maxVal,
  );
});

// ──────────────────────────────────────────────────────────────
// Concentration metrics
// ──────────────────────────────────────────────────────────────

class ConcentrationMetrics {
  const ConcentrationMetrics({
    required this.assetHhi,
    required this.currencyHhi,
    required this.regionHhi,
    required this.top3Share,
    required this.top3Labels,
    required this.largestLabel,
    required this.largestShare,
  });

  final double assetHhi; // 0–1 (lower = more diversified)
  final double currencyHhi;
  final double regionHhi;
  final double top3Share; // 0–1
  final List<String> top3Labels;
  final String largestLabel;
  final double largestShare; // 0–1
}

final concentrationProvider =
    FutureProvider.autoDispose<ConcentrationMetrics>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final accountMap = {for (final a in accounts) a.id: a};

  var grandTotal = 0.0;
  final assetVals = <String, double>{};
  final currencyVals = <String, double>{};
  final regionVals = <String, double>{};

  for (final a in assets) {
    final mv = a.marketValue?.toDouble() ?? 0;
    if (mv <= 0) continue;
    grandTotal += mv;
    final label = a.assetCode ?? (a.id.length >= 6 ? a.id.substring(0, 6) : a.id);
    assetVals[label] = (assetVals[label] ?? 0) + mv;
    currencyVals[a.currency] = (currencyVals[a.currency] ?? 0) + mv;
    final region = accountMap[a.accountId]?.sovereigntyRegion ?? '未知';
    regionVals[region] = (regionVals[region] ?? 0) + mv;
  }

  double hhi(Map<String, double> vals) {
    if (grandTotal <= 0) return 0;
    var h = 0.0;
    for (final v in vals.values) {
      final s = v / grandTotal;
      h += s * s;
    }
    return h;
  }

  final sorted = assetVals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top3 = sorted.take(3).toList();
  final top3Total = top3.fold<double>(0, (s, e) => s + e.value);

  return ConcentrationMetrics(
    assetHhi: hhi(assetVals),
    currencyHhi: hhi(currencyVals),
    regionHhi: hhi(regionVals),
    top3Share: grandTotal > 0 ? top3Total / grandTotal : 0,
    top3Labels: top3.map((e) => e.key).toList(),
    largestLabel: sorted.isNotEmpty ? sorted.first.key : '-',
    largestShare:
        grandTotal > 0 && sorted.isNotEmpty ? sorted.first.value / grandTotal : 0,
  );
});

// ──────────────────────────────────────────────────────────────
// Liquidity profile
// ──────────────────────────────────────────────────────────────

class LiquidityProfile {
  const LiquidityProfile({
    required this.highValue,
    required this.medValue,
    required this.lowValue,
    required this.total,
  });

  final double highValue;
  final double medValue;
  final double lowValue;
  final double total;

  double get highPct => total > 0 ? highValue / total * 100 : 0;
  double get medPct => total > 0 ? medValue / total * 100 : 0;
  double get lowPct => total > 0 ? lowValue / total * 100 : 0;
}

const _highLiquidityTypes = {AssetType.fxAsset, AssetType.cd};
const _medLiquidityTypes = {AssetType.stock, AssetType.fund, AssetType.crypto};

final liquidityProvider =
    FutureProvider.autoDispose<LiquidityProfile>((ref) async {
  final assets = await ref.watch(assetListProvider.future);
  double high = 0, med = 0, low = 0;
  for (final a in assets) {
    final mv = a.marketValue?.toDouble() ?? 0;
    if (mv <= 0) continue;
    if (_highLiquidityTypes.contains(a.assetType)) {
      high += mv;
    } else if (_medLiquidityTypes.contains(a.assetType)) {
      med += mv;
    } else {
      low += mv;
    }
  }
  return LiquidityProfile(
    highValue: high,
    medValue: med,
    lowValue: low,
    total: high + med + low,
  );
});

// ──────────────────────────────────────────────────────────────
// Financial health score (5 dimensions)
// ──────────────────────────────────────────────────────────────

/// Computes the 5-dimension financial health radar scores.
final healthScoreProvider =
    FutureProvider.autoDispose<List<RadarDimension>>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final acLinks = await ref.watch(accountChannelListProvider.future);

  if (assets.isEmpty) return [];

  // 1. Diversification = 1 - HHI(currency shares)
  final currencyTotals = <String, double>{};
  var grandTotal = 0.0;
  for (final a in assets) {
    final mv = a.marketValue?.toDouble() ?? 0;
    if (mv > 0) {
      currencyTotals[a.currency] = (currencyTotals[a.currency] ?? 0) + mv;
      grandTotal += mv;
    }
  }
  double hhi = 0;
  if (grandTotal > 0) {
    for (final v in currencyTotals.values) {
      final share = v / grandTotal;
      hhi += share * share;
    }
  }
  final diversification = (1 - hhi).clamp(0.0, 1.0);

  // 2. Liquidity = cash-like assets / total
  double cashLike = 0;
  for (final a in assets) {
    if (a.assetType == AssetType.fxAsset || a.assetType == AssetType.cd) {
      cashLike += a.marketValue?.toDouble() ?? 0;
    }
  }
  final liquidity = grandTotal > 0 ? (cashLike / grandTotal).clamp(0.0, 1.0) : 0.0;

  // 3. Channel Coverage = accounts with channel bindings / total accounts
  final linkedAccounts = acLinks.map((l) => l.accountId).toSet();
  final coverage = accounts.isNotEmpty
      ? (linkedAccounts.length / accounts.length).clamp(0.0, 1.0)
      : 0.0;

  // 4. Data Freshness = % of assets with valuation updated in past 24h
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  var freshCount = 0;
  for (final a in assets) {
    if (a.valuationTime != null && a.valuationTime!.isAfter(cutoff)) {
      freshCount++;
    }
  }
  final freshness = assets.isNotEmpty ? freshCount / assets.length : 0.0;

  // 5. Concentration Risk = 1 - (largest single asset / total)
  double maxSingle = 0;
  for (final a in assets) {
    final mv = a.marketValue?.toDouble() ?? 0;
    if (mv > maxSingle) maxSingle = mv;
  }
  final concentration = grandTotal > 0
      ? (1 - maxSingle / grandTotal).clamp(0.0, 1.0)
      : 0.0;

  return [
    RadarDimension(label: '分散度', value: diversification),
    RadarDimension(label: '流动性', value: liquidity),
    RadarDimension(label: '通道覆盖', value: coverage),
    RadarDimension(label: '数据时效', value: freshness),
    RadarDimension(label: '集中风险', value: concentration),
  ];
});
