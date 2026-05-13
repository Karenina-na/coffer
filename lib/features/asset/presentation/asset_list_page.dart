import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_number_text.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../../domain/usecases/value_assets_in_currency.dart';
import '../../account/presentation/account_providers.dart';
import 'asset_providers.dart';

/// Body-only widget for embedding inside a parent Scaffold (e.g. HoldingsPage).
class AssetListBody extends ConsumerWidget {
  const AssetListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(valuedAssetsProvider);
    final accountsAsync = ref.watch(accountListProvider);
    final valuationCurrency = ref.watch(valuationCurrencyProvider);
    return assetsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GwpColors.actionPrimary),
      ),
      error: (e, _) => GwpEmptyState.error(
        message: '加载失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(assetListProvider),
      ),
      data: (valued) {
        if (valued.assets.isEmpty) {
          return const GwpEmptyState(
            icon: Icons.show_chart_outlined,
            title: '还没有资产',
            subtitle: '从右上「更多 → 新建」添加第一个资产',
          );
        }
        final accounts = accountsAsync.when(
          data: (list) => list,
          loading: () => <Account>[],
          error: (_, _) => <Account>[],
        );
        final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
        return _AssetListView(
          assets: valued.assets,
          accounts: accounts,
          regionIndex: regionIndex,
          valuationCurrency: valuationCurrency,
          missingAssetIds: valued.missingAssetIds.toSet(),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Grouped asset list
// ──────────────────────────────────────────────────────────────

/// Number of top groups expanded by default.
const _kAutoExpandCount = 0;

class _AssetListView extends ConsumerStatefulWidget {
  const _AssetListView({
    required this.assets,
    required this.accounts,
    required this.regionIndex,
    required this.valuationCurrency,
    required this.missingAssetIds,
  });

  final List<ValuedAsset> assets;
  final List<Account> accounts;
  final RegionIndex regionIndex;
  final String valuationCurrency;
  final Set<String> missingAssetIds;

  @override
  ConsumerState<_AssetListView> createState() => _AssetListViewState();
}

class _AssetListViewState extends ConsumerState<_AssetListView> {
  final _expandedGroups = <String>{};
  final _regionOrder = <String>[];
  String? _draggingRegion;
  bool _initialized = false;

  List<ValuedAsset> get assets => widget.assets;
  List<Account> get accounts => widget.accounts;
  RegionIndex get regionIndex => widget.regionIndex;

  @override
  Widget build(BuildContext context) {
    var totalValue = Decimal.zero;
    var totalGain = Decimal.zero;
    var gainableCount = 0;
    for (final asset in assets) {
      if (asset.valuedAmount != null && asset.valuedAmount! > Decimal.zero) {
        totalValue += asset.valuedAmount!;
      }
      if (asset.valuedAmount != null &&
          asset.valuedCostBasis != null &&
          asset.valuedCostBasis! > Decimal.zero) {
        totalGain += asset.valuedAmount! - asset.valuedCostBasis!;
        gainableCount++;
      }
    }
    final totalD = totalValue.toDouble();

    final typeBreakdown = <AssetType, double>{};
    for (final asset in assets) {
      final mv = asset.valuedAmount?.toDouble() ?? 0;
      if (mv > 0) {
        typeBreakdown[asset.asset.assetType] =
            (typeBreakdown[asset.asset.assetType] ?? 0) + mv;
      }
    }

    final currencyBreakdown = <String, double>{};
    for (final asset in assets) {
      final mv = asset.valuedAmount?.toDouble() ?? 0;
      if (mv > 0) {
        currencyBreakdown[asset.asset.currency] =
            (currencyBreakdown[asset.asset.currency] ?? 0) + mv;
      }
    }

    final accountMap = {for (final account in accounts) account.id: account};
    final grouped = <String, Map<AccountType, Map<String, List<ValuedAsset>>>>{};
    final regionTotal = <String, Decimal>{};
    final typeTotalByRegion = <String, Map<AccountType, Decimal>>{};
    final accountTotal = <String, Decimal>{};

    for (final valuedAsset in assets) {
      final accountId = valuedAsset.asset.accountId;
      final account = accountMap[accountId];
      final region = account?.sovereigntyRegion ?? 'UNKNOWN';
      final accountType = account?.accountType ?? AccountType.bank;
      final amount = valuedAsset.valuedAmount ?? Decimal.zero;

      final typeGroups = grouped.putIfAbsent(
        region,
        () => <AccountType, Map<String, List<ValuedAsset>>>{},
      );
      final accountGroups = typeGroups.putIfAbsent(
        accountType,
        () => <String, List<ValuedAsset>>{},
      );
      accountGroups.putIfAbsent(accountId, () => []).add(valuedAsset);

      regionTotal[region] = (regionTotal[region] ?? Decimal.zero) + amount;
      final typeTotals = typeTotalByRegion.putIfAbsent(
        region,
        () => <AccountType, Decimal>{},
      );
      typeTotals[accountType] = (typeTotals[accountType] ?? Decimal.zero) + amount;
      accountTotal[accountId] = (accountTotal[accountId] ?? Decimal.zero) + amount;
    }

    final fallbackRegions = grouped.keys.toList()
      ..sort((a, b) {
        final valueCmp = (regionTotal[b] ?? Decimal.zero).compareTo(
          regionTotal[a] ?? Decimal.zero,
        );
        if (valueCmp != 0) return valueCmp;
        return regionLabel(regionIndex, a).compareTo(regionLabel(regionIndex, b));
      });
    _regionOrder.removeWhere((code) => !grouped.containsKey(code));
    for (final code in fallbackRegions) {
      if (!_regionOrder.contains(code)) _regionOrder.add(code);
    }
    final sortedRegions = List<String>.from(_regionOrder);

    if (!_initialized) {
      _initialized = true;
      for (var i = 0; i < sortedRegions.length && i < _kAutoExpandCount; i++) {
        _expandedGroups.add(sortedRegions[i]);
      }
      if (sortedRegions.length <= _kAutoExpandCount) {
        _expandedGroups.addAll(sortedRegions);
      }
    }

    final regionSections = <Widget>[
      for (final region in sortedRegions)
        _DraggableRegionSection(
          key: ValueKey('asset-region-$region'),
          region: region,
          draggingRegion: _draggingRegion,
          onDragStarted: () => setState(() => _draggingRegion = region),
          onDragEnded: () => setState(() => _draggingRegion = null),
          onAcceptRegion: (dragged) => setState(() {
            final from = _regionOrder.indexOf(dragged);
            final to = _regionOrder.indexOf(region);
            if (from == -1 || to == -1 || from == to) return;
            final moved = _regionOrder.removeAt(from);
            final insertAt = from < to ? to - 1 : to;
            _regionOrder.insert(insertAt, moved);
          }),
          header: _RegionHeader(
            region: region,
            accountCount: grouped[region]!.values.fold<int>(
              0,
              (sum, accountGroups) => sum + accountGroups.length,
            ),
            netWorth: regionTotal[region] ?? Decimal.zero,
            totalNetWorth: totalD,
            expanded: _expandedGroups.contains(region),
            regionIndex: regionIndex,
            onToggle: () => setState(() {
              if (_expandedGroups.contains(region)) {
                _expandedGroups.remove(region);
              } else {
                _expandedGroups.add(region);
              }
            }),
            dragHandle: null,
          ),
          children: _expandedGroups.contains(region)
              ? [
                  for (final accountType in _sortedAccountTypes(
                    region,
                    grouped[region]!,
                    typeTotalByRegion,
                  )) ...[
                    _AccountTypeHeader(
                      accountType: accountType,
                      accountCount: grouped[region]![accountType]!.length,
                      netWorth: typeTotalByRegion[region]?[accountType] ?? Decimal.zero,
                    ),
                    for (final accountId in _allAccounts(
                      grouped[region]![accountType]!,
                      accountMap,
                      accountTotal,
                    )) ...[
                      _AccountGroupHeader(
                        account: accountMap[accountId],
                        assets: grouped[region]![accountType]![accountId]!,
                        totalValue: totalD,
                      ),
                      for (final asset in grouped[region]![accountType]![accountId]!)
                        _AssetCard(asset: asset, totalValue: totalD),
                    ],
                  ],
                ]
              : const [],
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 112),
      children: [
        _PortfolioHero(
          totalValue: totalValue,
          totalGain: totalGain,
          assetCount: assets.length,
          valuationCurrency: widget.valuationCurrency,
          missingCount: widget.missingAssetIds.length,
          hasGainData: gainableCount > 0,
          typeBreakdown: typeBreakdown,
          currencyBreakdown: currencyBreakdown,
        ),
        ...regionSections,
      ],
    );
  }

  List<AccountType> _sortedAccountTypes(
    String region,
    Map<AccountType, Map<String, List<ValuedAsset>>> byType,
    Map<String, Map<AccountType, Decimal>> typeTotalByRegion,
  ) {
    final types = byType.keys.toList();
    types.sort((a, b) {
      final valueCmp =
          (typeTotalByRegion[region]?[b] ?? Decimal.zero).compareTo(
            typeTotalByRegion[region]?[a] ?? Decimal.zero,
          );
      if (valueCmp != 0) return valueCmp;
      return a.labelZh.compareTo(b.labelZh);
    });
    return types;
  }

  List<String> _allAccounts(
    Map<String, List<ValuedAsset>> accountGroups,
    Map<String, Account> accountMap,
    Map<String, Decimal> accountTotal,
  ) {
    final accountIds = accountGroups.keys.toList()
      ..sort((a, b) {
        final valueCmp = (accountTotal[b] ?? Decimal.zero).compareTo(
          accountTotal[a] ?? Decimal.zero,
        );
        if (valueCmp != 0) return valueCmp;
        final aName = accountMap[a]?.institutionName ?? a;
        final bName = accountMap[b]?.institutionName ?? b;
        return aName.compareTo(bName);
      });
    return accountIds;
  }
}

// ──────────────────────────────────────────────────────────────
// Portfolio hero card with donuts
// ──────────────────────────────────────────────────────────────

class _DraggableRegionSection extends StatelessWidget {
  const _DraggableRegionSection({
    super.key,
    required this.region,
    required this.draggingRegion,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onAcceptRegion,
    required this.header,
    required this.children,
  });

  final String region;
  final String? draggingRegion;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final ValueChanged<String> onAcceptRegion;
  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != region,
      onAcceptWithDetails: (details) => onAcceptRegion(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty && draggingRegion != region;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: active
                ? Border(
                    top: BorderSide(color: GwpColors.actionPrimary, width: 2),
                  )
                : null,
          ),
          child: Column(
            key: key,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LongPressDraggable<String>(
                data: region,
                onDragStarted: onDragStarted,
                onDragEnd: (_) => onDragEnded(),
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: GwpColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GwpColors.border, width: 0.5),
                    ),
                    child: Text(
                      header is _RegionHeader ? (header as _RegionHeader).labelText : region,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                child: header,
              ),
              ...children,
            ],
          ),
        );
      },
    );
  }
}

class _PortfolioHero extends StatelessWidget {
  const _PortfolioHero({
    required this.totalValue,
    required this.totalGain,
    required this.assetCount,
    required this.valuationCurrency,
    required this.missingCount,
    required this.hasGainData,
    required this.typeBreakdown,
    required this.currencyBreakdown,
  });

  final Decimal totalValue;
  final Decimal totalGain;
  final int assetCount;
  final String valuationCurrency;
  final int missingCount;
  final bool hasGainData;
  final Map<AssetType, double> typeBreakdown;
  final Map<String, double> currencyBreakdown;

  @override
  Widget build(BuildContext context) {
    final isUp = totalGain >= Decimal.zero;
    final gainPct = totalValue > Decimal.zero
        ? (totalGain.toDouble() / totalValue.toDouble() * 100)
        : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        GwpSpacing.base, GwpSpacing.sm, GwpSpacing.base, GwpSpacing.sm,
      ),
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GwpColors.surface2,
            GwpColors.actionPrimary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '组合总估值',
                      style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalValue > Decimal.zero
                          ? Money.format(totalValue, currency: valuationCurrency)
                          : '—',
                      style: const TextStyle(
                        fontFamily: GwpTypo.monoFont,
                        fontFeatures: GwpTypo.tabularFigures,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasGainData)
                      Row(
                        children: [
                          GwpNumberText(
                              value:
                                  '${isUp ? '+' : ''}${Money.format(totalGain, currency: valuationCurrency)}',
                              sign: totalGain > Decimal.zero
                                  ? ValueSign.positive
                                  : (totalGain < Decimal.zero
                                    ? ValueSign.negative
                                    : ValueSign.neutral),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            showIcon: true,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUp
                                  ? GwpColors.positiveBg
                                  : GwpColors.negativeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${isUp ? '+' : ''}${gainPct.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontFamily: GwpTypo.monoFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isUp
                                    ? GwpColors.positive
                                    : GwpColors.negative,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (missingCount > 0)
                      Text(
                        '$missingCount 项缺失汇率，未计入统计',
                        style: const TextStyle(
                          fontSize: 10,
                          color: GwpColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$assetCount 项资产',
                style:
                    const TextStyle(fontSize: 11, color: GwpColors.textMuted),
              ),
            ],
          ),
          // Breakdown donuts
          if (typeBreakdown.isNotEmpty || currencyBreakdown.isNotEmpty) ...[
            const SizedBox(height: GwpSpacing.md),
            const Divider(height: 1, color: GwpColors.border),
            const SizedBox(height: GwpSpacing.md),
            Row(
              children: [
                if (typeBreakdown.isNotEmpty)
                  Expanded(
                    child: _MiniDonut(
                      title: '按类型',
                      data: typeBreakdown.entries
                          .map((e) => _DonutSlice(
                                label: e.key.code,
                                value: e.value,
                                color: _assetTypeColors[e.key] ??
                                    GwpColors.actionPrimary,
                              ))
                          .toList(),
                    ),
                  ),
                if (typeBreakdown.isNotEmpty && currencyBreakdown.isNotEmpty)
                  const SizedBox(width: GwpSpacing.base),
                if (currencyBreakdown.isNotEmpty)
                  Expanded(
                    child: _MiniDonut(
                      title: '按币种',
                      data: currencyBreakdown.entries
                          .map((e) => _DonutSlice(
                                label: e.key,
                                value: e.value,
                                color: _currencyColor(e.key),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Mini donut chart
// ──────────────────────────────────────────────────────────────

class _DonutSlice {
  const _DonutSlice(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
}

class _MiniDonut extends StatelessWidget {
  const _MiniDonut({required this.title, required this.data});
  final String title;
  final List<_DonutSlice> data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...data]..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (s, e) => s + e.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: GwpColors.textMuted)),
        const SizedBox(height: GwpSpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: PieChart(PieChartData(
                sections: sorted
                    .map((s) => PieChartSectionData(
                          value: s.value,
                          color: s.color,
                          radius: 10,
                          showTitle: false,
                        ))
                    .toList(),
                sectionsSpace: 1,
                centerSpaceRadius: 16,
              )),
            ),
            const SizedBox(width: GwpSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in sorted.take(3)) _legendRow(s, total),
                  if (sorted.length > 3)
                    Text('+${sorted.length - 3} 更多',
                        style: const TextStyle(
                            fontSize: 9, color: GwpColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendRow(_DonutSlice s, double total) {
    final pct = total > 0 ? (s.value / total * 100).toStringAsFixed(2) : '0.00';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: s.color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(s.label,
                style: const TextStyle(
                    fontSize: 9, color: GwpColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text('$pct%',
              style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: GwpColors.textSecondary)),
        ],
      ),
    );
  }
}

Color _currencyColor(String ccy) => switch (ccy) {
      'CNY' => const Color(0xFFEF4444),
      'USD' => const Color(0xFF64748B),
      'HKD' => const Color(0xFFF59E0B),
      'SGD' => const Color(0xFF22C55E),
      'EUR' => const Color(0xFF38BDF8),
      'GBP' => const Color(0xFFA78BFA),
      'JPY' => const Color(0xFFEC4899),
      'BTC' => const Color(0xFFFB923C),
      'ETH' => const Color(0xFF6366F1),
      'USDT' => const Color(0xFF22C55E),
      _ => const Color(0xFF94A3B8),
    };

// ──────────────────────────────────────────────────────────────
// Region / type / account headers
// ──────────────────────────────────────────────────────────────

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({
    required this.region,
    required this.accountCount,
    required this.netWorth,
    required this.totalNetWorth,
    required this.expanded,
    required this.regionIndex,
    required this.onToggle,
    this.dragHandle,
  });

  final String region;
  final int accountCount;
  final Decimal netWorth;
  final double totalNetWorth;
  final bool expanded;
  final RegionIndex regionIndex;
  final VoidCallback onToggle;
  final Widget? dragHandle;

  String get labelText => '$regionLabelText ($accountCount)';
  String get regionLabelText => regionLabel(regionIndex, region);

  @override
  Widget build(BuildContext context) {
    final label = regionLabelText;
    final pct = totalNetWorth > 0
        ? '${(netWorth.toDouble() / totalNetWorth * 100).toStringAsFixed(1)}%'
        : null;
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GwpSpacing.base,
          GwpSpacing.base,
          GwpSpacing.base,
          GwpSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: regionColor(regionIndex, region),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  '$label ($accountCount)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: GwpColors.textMuted,
                  ),
                ),
                if (dragHandle != null) ...[
                  const SizedBox(width: 4),
                  dragHandle!,
                ],
                const Spacer(),
                if (netWorth > Decimal.zero) ...[
                  Text(
                    _compact(total: netWorth.toDouble()),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontFeatures: GwpTypo.tabularFigures,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: GwpColors.textMuted,
                    ),
                  ),
                  if (pct != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: regionColor(regionIndex, region).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pct,
                        style: TextStyle(
                          fontFamily: GwpTypo.monoFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: regionColor(regionIndex, region),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            if (totalNetWorth > 0 && netWorth > Decimal.zero) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (netWorth.toDouble() / totalNetWorth).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: GwpColors.surface2,
                  valueColor: AlwaysStoppedAnimation(
                    regionColor(regionIndex, region).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountTypeHeader extends StatelessWidget {
  const _AccountTypeHeader({
    required this.accountType,
    required this.accountCount,
    required this.netWorth,
  });

  final AccountType accountType;
  final int accountCount;
  final Decimal netWorth;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColors[accountType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[accountType] ?? Icons.account_balance_outlined;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GwpSpacing.xl,
        GwpSpacing.sm,
        GwpSpacing.base,
        GwpSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(typeIcon, size: 12, color: typeColor),
          ),
          const SizedBox(width: GwpSpacing.sm),
          Expanded(
            child: Text(
              '${accountType.labelZh} ($accountCount)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GwpColors.textSecondary,
              ),
            ),
          ),
          if (netWorth > Decimal.zero)
            Text(
              _compact(total: netWorth.toDouble()),
              style: TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: typeColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountGroupHeader extends StatelessWidget {
  const _AccountGroupHeader({
    required this.account,
    required this.assets,
    required this.totalValue,
  });

  final Account? account;
  final List<ValuedAsset> assets;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    var total = Decimal.zero;
    for (final asset in assets) {
      total += asset.valuedAmount ?? Decimal.zero;
    }
    final name = account?.institutionName ?? '未知账户';
    final pct = totalValue > 0
        ? (total.toDouble() / totalValue * 100).toStringAsFixed(1)
        : null;

    final typeMap = <String, double>{};
    for (final asset in assets) {
      final mv = asset.valuedAmount?.toDouble() ?? 0;
      if (mv > 0) {
        typeMap[asset.asset.assetType.name] =
            (typeMap[asset.asset.assetType.name] ?? 0) + mv;
      }
    }
    final sortedTypes = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final groupTotal = sortedTypes.fold<double>(0, (sum, entry) => sum + entry.value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GwpSpacing.xxl,
        GwpSpacing.sm,
        GwpSpacing.base,
        GwpSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: GwpColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$name (${assets.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textSecondary,
                  ),
                ),
              ),
              if (total > Decimal.zero) ...[
                Text(
                  _compact(total: total.toDouble()),
                  style: const TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontFeatures: GwpTypo.tabularFigures,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textMuted,
                  ),
                ),
                if (pct != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textMuted,
                    ),
                  ),
                ],
              ],
            ],
          ),
          if (sortedTypes.isNotEmpty && groupTotal > 0) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Row(
                  children: sortedTypes.map((entry) {
                    final frac = entry.value / groupTotal;
                    final color =
                        _assetTypeColorByName[entry.key] ?? GwpColors.textMuted;
                    return Expanded(
                      flex: (frac * 1000).round().clamp(1, 1000),
                      child: Container(color: color),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _compact({required double total}) {
  if (total >= 1e6) return '${(total / 1e6).toStringAsFixed(1)}M';
  if (total >= 1e3) return '${(total / 1e3).toStringAsFixed(0)}K';
  return total.toStringAsFixed(0);
}

// ──────────────────────────────────────────────────────────────
// Asset card (with proportion bar)
// ──────────────────────────────────────────────────────────────

const _typeIcons = <AccountType, IconData>{
  AccountType.bank: Icons.account_balance_outlined,
  AccountType.broker: Icons.show_chart_outlined,
  AccountType.insurance: Icons.health_and_safety_outlined,
  AccountType.payment: Icons.payment_outlined,
  AccountType.custody: Icons.lock_outlined,
  AccountType.cryptoExchange: Icons.currency_bitcoin_outlined,
  AccountType.cryptoWallet: Icons.wallet_outlined,
};

const _typeColors = <AccountType, Color>{
  AccountType.bank: Color(0xFF64748B),
  AccountType.broker: Color(0xFF22C55E),
  AccountType.insurance: Color(0xFFA78BFA),
  AccountType.payment: Color(0xFFF59E0B),
  AccountType.custody: Color(0xFF94A3B8),
  AccountType.cryptoExchange: Color(0xFFFB923C),
  AccountType.cryptoWallet: Color(0xFFEC4899),
};

const _assetTypeColors = <AssetType, Color>{
  AssetType.stock: Color(0xFF64748B),
  AssetType.equity: Color(0xFF6366F1),
  AssetType.fund: Color(0xFF22C55E),
  AssetType.bond: Color(0xFFF59E0B),
  AssetType.cd: Color(0xFFA78BFA),
  AssetType.crypto: Color(0xFFEC4899),
  AssetType.perpetual: Color(0xFFE879F9),
  AssetType.fxAsset: Color(0xFF38BDF8),
  AssetType.option: Color(0xFFEF4444),
  AssetType.future: Color(0xFF8B5CF6),
  AssetType.warrant: Color(0xFFFB923C),
  AssetType.policy: Color(0xFF6EE7B7),
  AssetType.contract: Color(0xFF94A3B8),
  AssetType.preciousMetal: Color(0xFFD4AF37),
};

const _assetTypeColorByName = <String, Color>{
  'stock': Color(0xFF64748B),
  'equity': Color(0xFF6366F1),
  'fund': Color(0xFF22C55E),
  'bond': Color(0xFFF59E0B),
  'cd': Color(0xFFA78BFA),
  'crypto': Color(0xFFEC4899),
  'perpetual': Color(0xFFE879F9),
  'fxAsset': Color(0xFF38BDF8),
  'option': Color(0xFFEF4444),
  'future': Color(0xFF8B5CF6),
  'warrant': Color(0xFFFB923C),
  'policy': Color(0xFF6EE7B7),
  'contract': Color(0xFF94A3B8),
  'preciousMetal': Color(0xFFD4AF37),
};

const _assetTypeIcons = <AssetType, IconData>{
  AssetType.stock: Icons.candlestick_chart_outlined,
  AssetType.equity: Icons.pie_chart_outline,
  AssetType.fund: Icons.auto_graph_outlined,
  AssetType.bond: Icons.receipt_long_outlined,
  AssetType.cd: Icons.savings_outlined,
  AssetType.crypto: Icons.currency_bitcoin_outlined,
  AssetType.perpetual: Icons.all_inclusive_outlined,
  AssetType.fxAsset: Icons.currency_exchange_outlined,
  AssetType.option: Icons.compare_arrows_outlined,
  AssetType.future: Icons.schedule_outlined,
  AssetType.warrant: Icons.assignment_outlined,
  AssetType.policy: Icons.health_and_safety_outlined,
  AssetType.contract: Icons.description_outlined,
  AssetType.preciousMetal: Icons.diamond_outlined,
};

class _AssetCard extends ConsumerWidget {
  const _AssetCard({required this.asset, required this.totalValue});

  final ValuedAsset asset;
  final double totalValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsset = asset.asset;
    final nativeMarket = asset.nativeValue;
    final valuedMarket = asset.valuedAmount;
    final valuedCostBasis = asset.valuedCostBasis;
    final typeColor =
        _assetTypeColors[rawAsset.assetType] ?? GwpColors.actionPrimary;
    final typeIcon = _assetTypeIcons[rawAsset.assetType] ?? Icons.show_chart;
    // Gain/loss
    Decimal? gain;
    double? gainPct;
    if (valuedMarket != null &&
        valuedCostBasis != null &&
        valuedCostBasis > Decimal.zero) {
      gain = valuedMarket - valuedCostBasis;
      if (valuedCostBasis > Decimal.zero) {
        gainPct = gain.toDouble() / valuedCostBasis.toDouble() * 100;
      }
    }
    final sign = gain == null
        ? ValueSign.neutral
        : (gain > Decimal.zero
            ? ValueSign.positive
            : (gain < Decimal.zero ? ValueSign.negative : ValueSign.neutral));

    // Proportion of total portfolio
    final mvD = valuedMarket?.toDouble() ?? 0;
    final proportion =
        totalValue > 0 && mvD > 0 ? (mvD / totalValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.xs,
      ),
      child: Material(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/assets/${rawAsset.id}'),
          onLongPress: () => _promptUpdatePrice(context, ref),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: GwpColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GwpSpacing.md, GwpSpacing.md, GwpSpacing.base, GwpSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child:
                                    Icon(typeIcon, size: 16, color: typeColor),
                              ),
                              const SizedBox(width: GwpSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      rawAsset.assetCode ?? rawAsset.assetType.labelZh,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: GwpColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rawAsset.assetType.labelZh} · 数量 ${rawAsset.quantity} · ${rawAsset.currency}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: GwpColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: GwpSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    nativeMarket == null
                                        ? '—'
                                        : Money.format(
                                            nativeMarket,
                                            currency: rawAsset.currency,
                                          ),
                                    style: const TextStyle(
                                      fontFamily: GwpTypo.monoFont,
                                      fontFeatures: GwpTypo.tabularFigures,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: GwpColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (gain != null && gainPct != null)
                                    GwpNumberText(
                                      value:
                                          '${gain > Decimal.zero ? '+' : ''}${gainPct.toStringAsFixed(2)}%',
                                      sign: sign,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      showIcon: true,
                                    )
                                  else
                                    Text(
                                      rawAsset.currency,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: GwpColors.textMuted,
                                        fontFamily: GwpTypo.monoFont,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Proportion bar
                          if (proportion > 0) ...[
                            const SizedBox(height: GwpSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: proportion,
                                      minHeight: 3,
                                      backgroundColor: GwpColors.surface3,
                                      valueColor: AlwaysStoppedAnimation(
                                          typeColor.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(proportion * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontFamily: GwpTypo.monoFont,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: GwpColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _promptUpdatePrice(BuildContext context, WidgetRef ref) async {
    final rawAsset = asset.asset;
    final ctrl = TextEditingController(
      text: rawAsset.currentPrice?.toString() ?? '',
    );
    final ok = await showDialog<Decimal>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更新价格 · ${rawAsset.assetCode ?? rawAsset.assetType.labelZh}'),
        content: TextField(
          controller: ctrl,
            keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
            labelText: '当前价 (${rawAsset.currency})',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final d = Decimal.tryParse(ctrl.text.trim());
              if (d != null && d >= Decimal.zero) Navigator.pop(ctx, d);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok == null) return;
    final r = await ref.read(valuateAssetUseCaseProvider)(
      assetId: rawAsset.id,
      newPrice: ok,
    );
    if (!context.mounted) return;
    r.when(
      ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('估值已更新')),
      ),
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: ${errorToMessage(e)}')),
      ),
    );
  }
}
