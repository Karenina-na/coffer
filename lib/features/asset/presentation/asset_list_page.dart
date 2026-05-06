import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_number_text.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../account/presentation/account_providers.dart';
import 'asset_providers.dart';

/// Body-only widget for embedding inside a parent Scaffold (e.g. HoldingsPage).
class AssetListBody extends ConsumerWidget {
  const AssetListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final accountsAsync = ref.watch(accountListProvider);
    return assetsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GwpColors.actionPrimary),
      ),
      error: (e, _) => GwpEmptyState.error(
        message: '加载失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(assetListProvider),
      ),
      data: (assets) {
        if (assets.isEmpty) {
          return const GwpEmptyState(
            icon: Icons.show_chart_outlined,
            title: '还没有资产',
            subtitle: '点击右下角按钮添加第一个资产',
          );
        }
        final accounts = accountsAsync.when(
          data: (list) => list,
          loading: () => <Account>[],
          error: (_, _) => <Account>[],
        );
        return _AssetListView(assets: assets, accounts: accounts);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// "Show more" button
// ──────────────────────────────────────────────────────────────

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.remaining, required this.onPressed});
  final int remaining;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.xs,
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GwpColors.textSecondary,
          side: const BorderSide(color: GwpColors.border, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: GwpSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.expand_more, size: 16),
        label: Text(
          '展开剩余 $remaining 项',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Grouped asset list
// ──────────────────────────────────────────────────────────────

/// Max items shown per group before "show more" is needed.
const _kGroupPreviewLimit = 3;

/// Number of top groups expanded by default.
const _kAutoExpandCount = 2;

class _AssetListView extends StatefulWidget {
  const _AssetListView({required this.assets, required this.accounts});

  final List<Asset> assets;
  final List<Account> accounts;

  @override
  State<_AssetListView> createState() => _AssetListViewState();
}

class _AssetListViewState extends State<_AssetListView> {
  final _expandedGroups = <String>{};
  final _showAllItems = <String>{};
  bool _initialized = false;

  List<Asset> get assets => widget.assets;
  List<Account> get accounts => widget.accounts;

  @override
  Widget build(BuildContext context) {
    // Portfolio summary
    var totalValue = Decimal.zero;
    var totalGain = Decimal.zero;
    var gainableCount = 0;
    for (final a in assets) {
      if (a.marketValue != null && a.marketValue! > Decimal.zero) {
        totalValue += a.marketValue!;
      }
      if (a.marketValue != null &&
          a.costPrice != null &&
          a.costPrice! > Decimal.zero) {
        totalGain += a.marketValue! - a.costPrice! * a.quantity;
        gainableCount++;
      }
    }
    final totalD = totalValue.toDouble();

    // Type breakdown
    final typeBreakdown = <AssetType, double>{};
    for (final a in assets) {
      final mv = a.marketValue?.toDouble() ?? 0;
      if (mv > 0) {
        typeBreakdown[a.assetType] = (typeBreakdown[a.assetType] ?? 0) + mv;
      }
    }

    // Currency breakdown
    final currencyBreakdown = <String, double>{};
    for (final a in assets) {
      final mv = a.marketValue?.toDouble() ?? 0;
      if (mv > 0) {
        currencyBreakdown[a.currency] =
            (currencyBreakdown[a.currency] ?? 0) + mv;
      }
    }

    // Group by account
    final accountMap = {for (final a in accounts) a.id: a};
    final grouped = <String, List<Asset>>{};
    for (final a in assets) {
      grouped.putIfAbsent(a.accountId, () => []).add(a);
    }
    final sortedAccountIds = grouped.keys.toList()
      ..sort((a, b) {
        final aTotal = grouped[a]!.fold<Decimal>(
          Decimal.zero,
          (s, asset) => s + (asset.marketValue ?? Decimal.zero),
        );
        final bTotal = grouped[b]!.fold<Decimal>(
          Decimal.zero,
          (s, asset) => s + (asset.marketValue ?? Decimal.zero),
        );
        return bTotal.compareTo(aTotal);
      });

    // Auto-expand top N groups on first build
    if (!_initialized) {
      _initialized = true;
      for (var i = 0; i < sortedAccountIds.length && i < _kAutoExpandCount; i++) {
        _expandedGroups.add(sortedAccountIds[i]);
      }
      if (sortedAccountIds.length <= _kAutoExpandCount) {
        _expandedGroups.addAll(sortedAccountIds);
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 112),
      children: [
        _PortfolioHero(
          totalValue: totalValue,
          totalGain: totalGain,
          assetCount: assets.length,
          hasGainData: gainableCount > 0,
          typeBreakdown: typeBreakdown,
          currencyBreakdown: currencyBreakdown,
        ),
        for (final accountId in sortedAccountIds) ...[
          _AccountGroupHeader(
            account: accountMap[accountId],
            assets: grouped[accountId]!,
            totalValue: totalD,
            expanded: _expandedGroups.contains(accountId),
            onToggle: () => setState(() {
              if (_expandedGroups.contains(accountId)) {
                _expandedGroups.remove(accountId);
              } else {
                _expandedGroups.add(accountId);
              }
            }),
          ),
          if (_expandedGroups.contains(accountId)) ...[
            for (final asset in _visibleItems(accountId, grouped[accountId]!))
              _AssetCard(asset: asset, totalValue: totalD),
            if (!_showAllItems.contains(accountId) &&
                grouped[accountId]!.length > _kGroupPreviewLimit)
              _ShowMoreButton(
                remaining:
                    grouped[accountId]!.length - _kGroupPreviewLimit,
                onPressed: () =>
                    setState(() => _showAllItems.add(accountId)),
              ),
          ],
        ],
      ],
    );
  }

  List<Asset> _visibleItems(String accountId, List<Asset> all) {
    if (_showAllItems.contains(accountId) || all.length <= _kGroupPreviewLimit) {
      return all;
    }
    return all.take(_kGroupPreviewLimit).toList();
  }
}

// ──────────────────────────────────────────────────────────────
// Portfolio hero card with donuts
// ──────────────────────────────────────────────────────────────

class _PortfolioHero extends StatelessWidget {
  const _PortfolioHero({
    required this.totalValue,
    required this.totalGain,
    required this.assetCount,
    required this.hasGainData,
    required this.typeBreakdown,
    required this.currencyBreakdown,
  });

  final Decimal totalValue;
  final Decimal totalGain;
  final int assetCount;
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
                          ? Money.format(totalValue, currency: 'CNY')
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
                                '${isUp ? '+' : ''}${Money.format(totalGain, currency: 'CNY')}',
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
    final pct = total > 0 ? (s.value / total * 100).toStringAsFixed(0) : '0';
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
// Account group header (with proportion)
// ──────────────────────────────────────────────────────────────

class _AccountGroupHeader extends StatelessWidget {
  const _AccountGroupHeader({
    required this.account,
    required this.assets,
    required this.totalValue,
    required this.expanded,
    required this.onToggle,
  });

  final Account? account;
  final List<Asset> assets;
  final double totalValue;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    var total = Decimal.zero;
    for (final a in assets) {
      total += a.marketValue ?? Decimal.zero;
    }
    final name = account?.institutionName ?? '未知账户';
    final region = account?.sovereigntyRegion ?? '';
    final pct = totalValue > 0
        ? (total.toDouble() / totalValue * 100).toStringAsFixed(1)
        : null;

    // Per-account asset type mini breakdown
    final typeMap = <String, double>{};
    for (final a in assets) {
      final mv = a.marketValue?.toDouble() ?? 0;
      if (mv > 0) {
        typeMap[a.assetType.name] = (typeMap[a.assetType.name] ?? 0) + mv;
      }
    }
    final sortedTypes = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final groupTotal = sortedTypes.fold<double>(0, (s, e) => s + e.value);

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GwpSpacing.base, GwpSpacing.base, GwpSpacing.base, GwpSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 14, color: GwpColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$name${region.isNotEmpty ? ' · $region' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text('(${assets.length})',
                    style: const TextStyle(
                        fontSize: 11, color: GwpColors.textMuted)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.chevron_right,
                      size: 16, color: GwpColors.textMuted),
                ),
                const Spacer(),
                if (total > Decimal.zero) ...[
                  Text(
                    _compact(total.toDouble()),
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
            // Mini stacked bar for type breakdown
            if (sortedTypes.isNotEmpty && groupTotal > 0) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: Row(
                    children: sortedTypes.map((e) {
                      final frac = e.value / groupTotal;
                      final color = _assetTypeColorByName[e.key] ??
                          GwpColors.textMuted;
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
      ),
    );
  }

  static String _compact(double val) {
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
    if (val >= 1e3) return '${(val / 1e3).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }
}

// ──────────────────────────────────────────────────────────────
// Asset card (with proportion bar)
// ──────────────────────────────────────────────────────────────

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

  final Asset asset;
  final double totalValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = asset.marketValue;
    final cost = asset.costPrice;
    final typeColor =
        _assetTypeColors[asset.assetType] ?? GwpColors.actionPrimary;
    final typeIcon = _assetTypeIcons[asset.assetType] ?? Icons.show_chart;
    final valueText =
        market == null ? '—' : Money.format(market, currency: asset.currency);

    // Gain/loss
    Decimal? gain;
    double? gainPct;
    if (market != null && cost != null && cost > Decimal.zero) {
      final costBasis = cost * asset.quantity;
      gain = market - costBasis;
      if (costBasis > Decimal.zero) {
        gainPct = gain.toDouble() / costBasis.toDouble() * 100;
      }
    }
    final sign = gain == null
        ? ValueSign.neutral
        : (gain > Decimal.zero
            ? ValueSign.positive
            : (gain < Decimal.zero ? ValueSign.negative : ValueSign.neutral));

    // Proportion of total portfolio
    final mvD = market?.toDouble() ?? 0;
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
          onTap: () => context.push('/assets/${asset.id}'),
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
                                      asset.assetCode ?? asset.assetType.labelZh,
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
                                      '${asset.assetType.labelZh} · 数量 ${asset.quantity} · ${asset.currency}',
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
                                  GwpNumberText(
                                    value: valueText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
                                      asset.currency,
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
    final ctrl = TextEditingController(
      text: asset.currentPrice?.toString() ?? '',
    );
    final ok = await showDialog<Decimal>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更新价格 · ${asset.assetCode ?? asset.assetType.labelZh}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '当前价 (${asset.currency})',
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
      assetId: asset.id,
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
