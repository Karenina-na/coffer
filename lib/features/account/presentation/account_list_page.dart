import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/region_meta.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_number_text.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/usecases/value_assets_in_currency.dart';
import '../../asset/presentation/asset_providers.dart';
import 'account_providers.dart';
import '../../../data/providers/dict_providers.dart';

/// Body-only widget for embedding inside a parent Scaffold (e.g. HoldingsPage).
/// Renders loading / error / empty / list states.
class AccountListBody extends ConsumerWidget {
  const AccountListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);
    final assetsAsync = ref.watch(valuedAssetsProvider);
    final valuationCurrency = ref.watch(valuationCurrencyProvider);
    return accountsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GwpColors.actionPrimary),
      ),
      error: (e, _) => GwpEmptyState.error(
        message: '加载失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(accountListProvider),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const GwpEmptyState(
            icon: Icons.account_balance_outlined,
            title: '还没有账户',
            subtitle: '从右上「更多 → 新建」添加第一个账户',
          );
        }
        final assets = assetsAsync.when(
          data: (valued) => valued.assets,
          loading: () => <ValuedAsset>[],
          error: (_, _) => <ValuedAsset>[],
        );
        final missingAssetIds = assetsAsync.when(
          data: (valued) => valued.missingAssetIds.toSet(),
          loading: () => <String>{},
          error: (_, _) => <String>{},
        );
        final regionIndex =
            ref.watch(regionMetaIndexProvider).value ?? const {};
        return _AccountListView(
          accounts: accounts,
          assets: assets,
          regionIndex: regionIndex,
          valuationCurrency: valuationCurrency,
          missingAssetIds: missingAssetIds,
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Aggregate data + grouped list
// ──────────────────────────────────────────────────────────────

/// Number of top groups expanded by default.
const _kAutoExpandCount = 2;

class _AccountListView extends ConsumerStatefulWidget {
  const _AccountListView({
    required this.accounts,
    required this.assets,
    required this.regionIndex,
    required this.valuationCurrency,
    required this.missingAssetIds,
  });

  final List<Account> accounts;
  final List<ValuedAsset> assets;
  final RegionIndex regionIndex;
  final String valuationCurrency;
  final Set<String> missingAssetIds;

  @override
  ConsumerState<_AccountListView> createState() => _AccountListViewState();
}

class _AccountListViewState extends ConsumerState<_AccountListView> {
  final _expandedGroups = <String>{};
  final _regionOrder = <String>[];
  bool _initialized = false;

  List<Account> get accounts => widget.accounts;
  List<ValuedAsset> get assets => widget.assets;
  RegionIndex get regionIndex => widget.regionIndex;

  @override
  Widget build(BuildContext context) {
    final netWorth = <String, Decimal>{};
    final assetCount = <String, int>{};
    final assetsByAccountId = <String, List<ValuedAsset>>{};
    for (final valuedAsset in assets) {
      final accountId = valuedAsset.asset.accountId;
      assetsByAccountId.putIfAbsent(accountId, () => []).add(valuedAsset);
      final mv = valuedAsset.valuedAmount;
      if (mv != null && mv > Decimal.zero) {
        netWorth[accountId] = (netWorth[accountId] ?? Decimal.zero) + mv;
      }
      assetCount[accountId] = (assetCount[accountId] ?? 0) + 1;
    }

    final typeValue = <AccountType, double>{};
    for (final account in accounts) {
      final value = (netWorth[account.id] ?? Decimal.zero).toDouble();
      if (value > 0) {
        typeValue[account.accountType] =
            (typeValue[account.accountType] ?? 0) + value;
      }
    }

    final regionValue = <String, double>{};
    for (final account in accounts) {
      final value = (netWorth[account.id] ?? Decimal.zero).toDouble();
      if (value > 0) {
        regionValue[account.sovereigntyRegion] =
            (regionValue[account.sovereigntyRegion] ?? 0) + value;
      }
    }

    var totalNetWorth = Decimal.zero;
    for (final value in netWorth.values) {
      totalNetWorth += value;
    }

    final grouped = <String, Map<AccountType, List<Account>>>{};
    final regionNetWorth = <String, Decimal>{};
    final typeNetWorthByRegion = <String, Map<AccountType, Decimal>>{};
    for (final account in accounts) {
      final regionGroups = grouped.putIfAbsent(
        account.sovereigntyRegion,
        () => <AccountType, List<Account>>{},
      );
      regionGroups.putIfAbsent(account.accountType, () => []).add(account);
      final value = netWorth[account.id] ?? Decimal.zero;
      regionNetWorth[account.sovereigntyRegion] =
          (regionNetWorth[account.sovereigntyRegion] ?? Decimal.zero) + value;
      final typeTotals = typeNetWorthByRegion.putIfAbsent(
        account.sovereigntyRegion,
        () => <AccountType, Decimal>{},
      );
      typeTotals[account.accountType] =
          (typeTotals[account.accountType] ?? Decimal.zero) + value;
    }

    for (final regionGroups in grouped.values) {
      for (final accountsInType in regionGroups.values) {
        accountsInType.sort((a, b) {
          final valueCmp = (netWorth[b.id] ?? Decimal.zero).compareTo(
            netWorth[a.id] ?? Decimal.zero,
          );
          if (valueCmp != 0) return valueCmp;
          return a.institutionName.compareTo(b.institutionName);
        });
      }
    }

    final fallbackRegions = grouped.keys.toList()
      ..sort((a, b) {
        final valueCmp = (regionNetWorth[b] ?? Decimal.zero).compareTo(
          regionNetWorth[a] ?? Decimal.zero,
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

    final activeCount = accounts
        .where((account) => account.status == AccountStatus.active)
        .length;
    final totalD = totalNetWorth.toDouble();

    final regionSections = <Widget>[
      for (final region in sortedRegions)
        _DraggableRegionSection(
          key: ValueKey('account-region-$region'),
          region: region,
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
              (sum, accountsInType) => sum + accountsInType.length,
            ),
            netWorth: regionNetWorth[region] ?? Decimal.zero,
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
                    typeNetWorthByRegion,
                  )) ...[
                    _AccountTypeHeader(
                      accountType: accountType,
                      accountCount: grouped[region]![accountType]!.length,
                      netWorth:
                          typeNetWorthByRegion[region]?[accountType] ?? Decimal.zero,
                    ),
                    for (final account in grouped[region]![accountType]!)
                      _AccountCard(
                        account: account,
                        netWorth: netWorth[account.id],
                        assetCount: assetCount[account.id] ?? 0,
                        totalNetWorth: totalD,
                        accountAssets: assetsByAccountId[account.id] ?? const [],
                      ),
                  ],
                ]
              : const [],
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 112),
      children: [
        _HeroCard(
          totalNetWorth: totalNetWorth,
          totalAccounts: accounts.length,
          activeCount: activeCount,
          regionCount: grouped.length,
          totalAssets: assets.length,
          valuationCurrency: widget.valuationCurrency,
          missingCount: widget.missingAssetIds.length,
          typeValue: typeValue,
          regionValue: regionValue,
          regionIndex: regionIndex,
        ),
        ...regionSections,
      ],
    );
  }

  List<AccountType> _sortedAccountTypes(
    String region,
    Map<AccountType, List<Account>> byType,
    Map<String, Map<AccountType, Decimal>> typeNetWorthByRegion,
  ) {
    final types = byType.keys.toList();
    types.sort((a, b) {
      final valueCmp =
          (typeNetWorthByRegion[region]?[b] ?? Decimal.zero).compareTo(
            typeNetWorthByRegion[region]?[a] ?? Decimal.zero,
          );
      if (valueCmp != 0) return valueCmp;
      return a.labelZh.compareTo(b.labelZh);
    });
    return types;
  }

}

// ──────────────────────────────────────────────────────────────
// Hero card with net worth + mini donuts
// ──────────────────────────────────────────────────────────────

class _DraggableRegionSection extends StatelessWidget {
  const _DraggableRegionSection({
    super.key,
    required this.region,
    required this.onAcceptRegion,
    required this.header,
    required this.children,
  });

  final String region;
  final ValueChanged<String> onAcceptRegion;
  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != region,
      onAcceptWithDetails: (details) => onAcceptRegion(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totalNetWorth,
    required this.totalAccounts,
    required this.activeCount,
    required this.regionCount,
    required this.totalAssets,
    required this.valuationCurrency,
    required this.missingCount,
    required this.typeValue,
    required this.regionValue,
    required this.regionIndex,
  });

  final Decimal totalNetWorth;
  final int totalAccounts;
  final int activeCount;
  final int regionCount;
  final int totalAssets;
  final String valuationCurrency;
  final int missingCount;
  final Map<AccountType, double> typeValue;
  final Map<String, double> regionValue;
  final RegionIndex regionIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        GwpSpacing.base,
        GwpSpacing.sm,
        GwpSpacing.base,
        GwpSpacing.sm,
      ),
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GwpColors.actionPrimary.withValues(alpha: 0.12),
            GwpColors.surface2,
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
          // Net worth headline
          const Text(
            '账户总净值',
            style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            totalNetWorth > Decimal.zero
                ? Money.format(totalNetWorth, currency: valuationCurrency)
                : '—',
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: GwpColors.textPrimary,
            ),
          ),
          if (missingCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$missingCount 项缺失汇率，未计入统计',
              style: const TextStyle(fontSize: 10, color: GwpColors.warning),
            ),
          ],
          const SizedBox(height: GwpSpacing.md),
          // KPI row
          Row(
            children: [
              _MiniStat(value: '$totalAccounts', label: '账户'),
              _vertDiv(),
              _MiniStat(value: '$activeCount', label: '活跃'),
              _vertDiv(),
              _MiniStat(value: '$regionCount', label: '地区'),
              _vertDiv(),
              _MiniStat(value: '$totalAssets', label: '资产'),
            ],
          ),
          // Mini donut charts row
          if (typeValue.isNotEmpty || regionValue.isNotEmpty) ...[
            const SizedBox(height: GwpSpacing.md),
            const Divider(height: 1, color: GwpColors.border),
            const SizedBox(height: GwpSpacing.md),
            Row(
              children: [
                if (typeValue.isNotEmpty)
                  Expanded(
                    child: _MiniDonut(
                      title: '按类型',
                      data: typeValue.entries
                          .map(
                            (e) => _DonutSlice(
                              label: e.key.labelZh,
                              value: e.value,
                              color:
                                  _typeColors[e.key] ?? GwpColors.actionPrimary,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (typeValue.isNotEmpty && regionValue.isNotEmpty)
                  const SizedBox(width: GwpSpacing.base),
                if (regionValue.isNotEmpty)
                  Expanded(
                    child: _MiniDonut(
                      title: '按地区',
                      data: regionValue.entries
                          .map(
                            (e) => _DonutSlice(
                              label: regionLabel(regionIndex, e.key),
                              value: e.value,
                              color: regionColor(regionIndex, e.key),
                            ),
                          )
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

  static Widget _vertDiv() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: GwpSpacing.md),
    color: GwpColors.border,
  );
}

// ──────────────────────────────────────────────────────────────
// Mini donut chart (inline, lightweight)
// ──────────────────────────────────────────────────────────────

class _DonutSlice {
  const _DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: GwpColors.textMuted,
          ),
        ),
        const SizedBox(height: GwpSpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: PieChart(
                PieChartData(
                  sections: sorted.map((s) {
                    return PieChartSectionData(
                      value: s.value,
                      color: s.color,
                      radius: 10,
                      showTitle: false,
                    );
                  }).toList(),
                  sectionsSpace: 1,
                  centerSpaceRadius: 16,
                ),
              ),
            ),
            const SizedBox(width: GwpSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in sorted.take(3)) _legendRow(s, total),
                  if (sorted.length > 3)
                    Text(
                      '+${sorted.length - 3} 更多',
                      style: const TextStyle(
                        fontSize: 9,
                        color: GwpColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendRow(_DonutSlice s, double total) {
    final pct = total > 0
        ? displayPercentDouble(s.value / total * 100)
        : '0.00%';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              s.label,
              style: const TextStyle(
                fontSize: 9,
                color: GwpColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              pct,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: GwpColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GwpColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: GwpColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Region group header (with proportion bar)
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
        ? displayPercentDouble(netWorth.toDouble() / totalNetWorth * 100)
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
                    _compactValue(netWorth),
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

  static String _compactValue(Decimal val) => compactValue(val.toDouble());
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
              compactValue(netWorth.toDouble()),
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

// ──────────────────────────────────────────────────────────────
// Account card (with proportion bar + asset type breakdown)
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

const _assetTypeColors = <String, Color>{
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

class _AccountCard extends ConsumerWidget {
  const _AccountCard({
    required this.account,
    required this.netWorth,
    required this.assetCount,
    required this.totalNetWorth,
    required this.accountAssets,
  });

  final Account account;
  final Decimal? netWorth;
  final int assetCount;
  final double totalNetWorth;
  final List<ValuedAsset> accountAssets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor =
        _typeColors[account.accountType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[account.accountType] ?? Icons.account_balance;
    final nw = netWorth ?? Decimal.zero;
    final proportion = totalNetWorth > 0
        ? (nw.toDouble() / totalNetWorth).clamp(0.0, 1.0)
        : 0.0;

    // Asset type breakdown for this account
    final breakdown = <String, double>{};
    for (final a in accountAssets) {
      final mv = a.valuedAmount?.toDouble() ?? 0;
      if (mv > 0) {
        breakdown[a.asset.assetType.name] =
            (breakdown[a.asset.assetType.name] ?? 0) + mv;
      }
    }
    final sortedTypes = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          onTap: () => context.push('/accounts/${account.id}'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: GwpColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left color bar
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
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            GwpSpacing.md,
                            GwpSpacing.md,
                            GwpSpacing.base,
                            GwpSpacing.sm,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      typeIcon,
                                      size: 18,
                                      color: typeColor,
                                    ),
                                  ),
                                  const SizedBox(width: GwpSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          account.institutionName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: GwpColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          [
                                            account.accountType.labelZh,
                                            if (assetCount > 0) '$assetCount 项资产',
                                            if (account.accountNo != null)
                                              account.accountNo!,
                                          ].join(' · '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: GwpColors.textMuted,
                                          ),
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
                                      if (nw > Decimal.zero)
                                        GwpNumberText(
                                          value: Money.format(
                                            nw,
                                            currency: ref.watch(valuationCurrencyProvider),
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        )
                                      else
                                        const Text(
                                          '—',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: GwpColors.textMuted,
                                            fontFamily: GwpTypo.monoFont,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      _statusBadge(account.status),
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
                                            typeColor.withValues(alpha: 0.6),
                                          ),
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
                              // Asset type breakdown chips
                              if (sortedTypes.isNotEmpty) ...[
                                const SizedBox(height: GwpSpacing.sm),
                                _AssetTypeBar(types: sortedTypes),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _statusBadge(AccountStatus status) {
    final (label, variant) = switch (status) {
      AccountStatus.active => ('ACTIVE', StatusVariant.positive),
      AccountStatus.inactive => ('INACTIVE', StatusVariant.muted),
      AccountStatus.dormant => ('DORMANT', StatusVariant.warning),
      AccountStatus.closed => ('CLOSED', StatusVariant.negative),
    };
    return GwpStatusBadge(label: label, variant: variant);
  }

}

// ──────────────────────────────────────────────────────────────
// Per-account asset type breakdown (stacked color bar)
// ──────────────────────────────────────────────────────────────

class _AssetTypeBar extends StatelessWidget {
  const _AssetTypeBar({required this.types});
  final List<MapEntry<String, double>> types;

  @override
  Widget build(BuildContext context) {
    final total = types.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        // Stacked color bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Row(
              children: types.map((e) {
                final frac = e.value / total;
                return Expanded(
                  flex: (frac * 1000).round().clamp(1, 1000),
                  child: Container(
                    color: _assetTypeColors[e.key] ?? GwpColors.textMuted,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Legend chips
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: types.take(4).map((e) {
            final pct = (e.value / total * 100).toStringAsFixed(0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _assetTypeColors[e.key] ?? GwpColors.textMuted,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${e.key} $pct%',
                  style: const TextStyle(
                    fontSize: 8,
                    color: GwpColors.textMuted,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
