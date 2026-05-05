import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/gwp_bar_rank.dart';
import '../../../core/ui/gwp_radar_chart.dart';
import 'portfolio_providers.dart';

/// Fourth tab body in holdings page — portfolio analysis dashboard.
class PortfolioAnalysisBody extends ConsumerWidget {
  const PortfolioAnalysisBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.md,
      ),
      children: const [
        _SnapshotHero(),
        SizedBox(height: GwpSpacing.base),
        _AllocationTriptych(),
        SizedBox(height: GwpSpacing.base),
        _AssetRankingSection(),
        SizedBox(height: GwpSpacing.base),
        _DimensionExplorer(),
        SizedBox(height: GwpSpacing.base),
        _CurrencyExposureSection(),
        SizedBox(height: GwpSpacing.base),
        _RiskOverviewSection(),
        SizedBox(height: GwpSpacing.base),
        _HealthRadarSection(),
        SizedBox(height: GwpSpacing.xxl),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Color palette for allocation charts
// ──────────────────────────────────────────────────────────────

const _allocationPalette = [
  Color(0xFF64748B),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFFA78BFA),
  Color(0xFF38BDF8),
  Color(0xFFFB923C),
  Color(0xFF14B8A6),
  Color(0xFF6366F1),
  Color(0xFFEF4444),
];

Color _sliceColor(int index) => _allocationPalette[index % _allocationPalette.length];

// ──────────────────────────────────────────────────────────────
// Compact value formatter
// ──────────────────────────────────────────────────────────────
// heroFormat / compactValueCJK 已提取到 lib/core/ui/format_utils.dart

// ──────────────────────────────────────────────────────────────
// §1  Portfolio Snapshot Hero
// ──────────────────────────────────────────────────────────────

class _SnapshotHero extends ConsumerWidget {
  const _SnapshotHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioSnapshotProvider);
    return async.when(
      loading: () => const _HeroShimmer(),
      error: (e, _) => _SectionCard(
        icon: Icons.analytics_outlined,
        iconColor: GwpColors.negative,
        title: '投资组合概览',
        child: _Error(e),
      ),
      data: (snap) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GwpColors.surface3, GwpColors.surface1],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GwpColors.borderStrong, width: 0.5),
        ),
        padding: const EdgeInsets.all(GwpSpacing.lg),
        child: Column(
          children: [
            // Total net worth
            Text(
              heroFormat(snap.netWorth),
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: GwpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '总净值 · ${snap.baseCurrency}',
              style: const TextStyle(
                fontSize: 12,
                color: GwpColors.textMuted,
              ),
            ),
            if (snap.missingRateCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${snap.missingRateCount} 项缺少汇率',
                style: const TextStyle(
                  fontSize: 10,
                  color: GwpColors.warning,
                ),
              ),
            ],
            const SizedBox(height: GwpSpacing.lg),
            // Stat chips row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  value: '${snap.accountCount}',
                  label: '账户',
                  icon: Icons.account_balance_outlined,
                ),
                _StatChip(
                  value: '${snap.assetCount}',
                  label: '资产',
                  icon: Icons.pie_chart_outline,
                ),
                _StatChip(
                  value: '${snap.currencyCount}',
                  label: '币种',
                  icon: Icons.currency_exchange,
                ),
                _StatChip(
                  value: '${snap.regionCount}',
                  label: '地区',
                  icon: Icons.public_outlined,
                ),
                _StatChip(
                  value: '${snap.institutionCount}',
                  label: '机构',
                  icon: Icons.business_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  const _HeroShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: GwpColors.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: GwpColors.actionPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: GwpColors.actionPrimary),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GwpColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: GwpColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §2  Allocation Triptych (3 mini donuts)
// ──────────────────────────────────────────────────────────────

class _AllocationTriptych extends ConsumerWidget {
  const _AllocationTriptych();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AllocationCard(
            title: '资产类型',
            async: ref.watch(portfolioByTypeProvider),
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Expanded(
          child: _AllocationCard(
            title: '币种分布',
            async: ref.watch(portfolioByCurrencyProvider),
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Expanded(
          child: _AllocationCard(
            title: '地区分布',
            async: ref.watch(portfolioByRegionProvider),
          ),
        ),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.title,
    required this.async,
  });

  final String title;
  final AsyncValue<List<AllocationSlice>> async;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(GwpSpacing.sm),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GwpColors.textMuted,
            ),
          ),
          const SizedBox(height: GwpSpacing.sm),
          async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
            error: (_, _) => const SizedBox(
              height: 80,
              child: Center(
                child: Icon(Icons.error_outline, color: GwpColors.negative, size: 20),
              ),
            ),
            data: (slices) {
              if (slices.isEmpty) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      '—',
                      style: TextStyle(color: GwpColors.textMuted, fontSize: 16),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: _MiniDonutPainter(slices: slices),
                      child: Center(
                        child: Text(
                          '${slices.first.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: GwpColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: GwpSpacing.sm),
                  for (var i = 0; i < slices.length && i < 3; i++)
                    _LegendRow(
                      color: _sliceColor(i),
                      label: slices[i].label,
                      pct: slices[i].percentage,
                    ),
                  if (slices.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${slices.length - 3} 项',
                        style: const TextStyle(
                          fontSize: 9,
                          color: GwpColors.textMuted,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniDonutPainter extends CustomPainter {
  const _MiniDonutPainter({required this.slices});
  final List<AllocationSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    var startAngle = -pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].percentage / 100 * 2 * pi;
      final paint = Paint()
        ..color = _sliceColor(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter old) => true;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.pct,
  });

  final Color color;
  final String label;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: GwpColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontSize: 9,
              color: GwpColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §3  Asset Ranking (Top 10)
// ──────────────────────────────────────────────────────────────

class _AssetRankingSection extends ConsumerWidget {
  const _AssetRankingSection();

  // Muted institutional palette: actionPrimary + surface tones.
  static const _rankColors = [
    Color(0xFF6B7280),
    Color(0xFF5B6470),
    Color(0xFF4B5560),
    Color(0xFF3B4650),
    Color(0xFF374151),
    Color(0xFF334155),
    Color(0xFF2F3D4F),
    Color(0xFF2B3949),
    Color(0xFF273543),
    Color(0xFF23313D),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assetTop10Provider);
    return _SectionCard(
      icon: Icons.emoji_events_outlined,
      iconColor: GwpColors.warning,
      title: '资产 Top 10',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _Error(e),
        data: (items) {
          if (items.isEmpty) return const _Empty();
          final total = items.fold<double>(0, (s, i) => s + i.value);
          final ranked = items.map((item) {
            final idx = items.indexOf(item);
            return RankItem(
              label: '${idx + 1}. ${item.label}',
              value: item.value,
              color: _rankColors[idx.clamp(0, _rankColors.length - 1)],
            );
          }).toList();
          return Column(
            children: [
              SizedBox(
                height: (ranked.length * 24.0).clamp(120, 240),
                child: GwpBarRank(
                  items: ranked,
                  formatValue: (v) => '${total > 0 ? (v / total * 100).toStringAsFixed(1) : '0.0'}%  ${compactValueCJK(v)}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '合计 ${compactValueCJK(total)}',
                style: const TextStyle(fontSize: 11, color: GwpColors.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DimensionExplorer extends ConsumerStatefulWidget {
  const _DimensionExplorer();

  @override
  ConsumerState<_DimensionExplorer> createState() => _DimensionExplorerState();
}

class _DimensionExplorerState extends ConsumerState<_DimensionExplorer> {
  int _selectedIndex = 0;

  static const _labels = ['按类型', '按币种', '按地区', '按机构'];
  static const _icons = [
    Icons.category_outlined,
    Icons.currency_exchange,
    Icons.public_outlined,
    Icons.business_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final providers = [
      portfolioByTypeProvider,
      portfolioByCurrencyProvider,
      portfolioByRegionProvider,
      portfolioByInstitutionProvider,
    ];
    final async = ref.watch(providers[_selectedIndex]);

    return _SectionCard(
      icon: Icons.dashboard_outlined,
      iconColor: GwpColors.info,
      title: '维度探索',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _labels.length,
              separatorBuilder: (_, _) => const SizedBox(width: GwpSpacing.sm),
              itemBuilder: (_, i) => ChoiceChip(
                avatar: Icon(_icons[i], size: 14),
                label: Text(_labels[i]),
                selected: _selectedIndex == i,
                onSelected: (_) => setState(() => _selectedIndex = i),
                selectedColor:
                    GwpColors.actionPrimary.withValues(alpha: 0.15),
                backgroundColor: GwpColors.surface2,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _selectedIndex == i
                      ? GwpColors.actionPrimary
                      : GwpColors.textSecondary,
                ),
                side: BorderSide(
                  color: _selectedIndex == i
                      ? GwpColors.actionPrimary.withValues(alpha: 0.4)
                      : GwpColors.border,
                  width: 0.5,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          const SizedBox(height: GwpSpacing.md),
          // Proportion bars
          async.when(
            loading: () => const _Loading(),
            error: (e, _) => _Error(e),
            data: (slices) {
              if (slices.isEmpty) return const _Empty();
              final maxPct = slices.first.percentage;
              return Column(
                children: [
                  for (var i = 0; i < slices.length; i++) ...[
                    _ProportionRow(
                      slice: slices[i],
                      index: i,
                      maxPct: maxPct,
                    ),
                    if (i < slices.length - 1)
                      const SizedBox(height: GwpSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProportionRow extends StatelessWidget {
  const _ProportionRow({
    required this.slice,
    required this.index,
    required this.maxPct,
  });

  final AllocationSlice slice;
  final int index;
  final double maxPct;

  @override
  Widget build(BuildContext context) {
    final barFraction = maxPct > 0 ? (slice.percentage / maxPct).clamp(0.0, 1.0) : 0.0;
    final color = _sliceColor(index);

    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            slice.label,
            style: const TextStyle(
              fontSize: 11,
              color: GwpColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 16,
              child: LinearProgressIndicator(
                value: barFraction,
                backgroundColor: GwpColors.surface3,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${slice.percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 10,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 44,
          child: Text(
            compactValueCJK(slice.value),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: GwpColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §5  Currency Exposure Heat Matrix
// ──────────────────────────────────────────────────────────────

class _CurrencyExposureSection extends ConsumerWidget {
  const _CurrencyExposureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currencyExposureProvider);
    return _SectionCard(
      icon: Icons.grid_on_outlined,
      iconColor: GwpColors.info,
      title: '币种敞口热力图',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _Error(e),
        data: (matrix) {
          if (matrix.accounts.isEmpty || matrix.currencies.isEmpty) {
            return const _Empty();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildGrid(matrix),
              ),
              const SizedBox(height: GwpSpacing.sm),
              _HeatLegend(maxValue: matrix.maxValue),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(HeatMatrixData m) {
    const cellW = 64.0;
    const cellH = 38.0;
    const labelW = 84.0;
    const headerStyle = TextStyle(
      fontSize: 10,
      color: GwpColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    const cellStyle = TextStyle(
      fontFamily: GwpTypo.monoFont,
      fontSize: 10,
      color: GwpColors.textPrimary,
    );

    // Institution palette: dark steel → muted accent gradient.
    Color heatColor(double intensity) {
      if (intensity <= 0) return GwpColors.surface2;
      final t = intensity.clamp(0.0, 1.0);
      return Color.lerp(
        GwpColors.actionPrimary.withValues(alpha: 0.15),
        GwpColors.actionPrimary,
        t,
      )!;
    }

    // Calculate totals
    final rowTotal = <String, double>{};
    final colTotal = <String, double>{};
    for (final acct in m.accounts) {
      for (final cur in m.currencies) {
        final v = m.cells[(acct, cur)] ?? 0;
        rowTotal[acct] = (rowTotal[acct] ?? 0) + v;
        colTotal[cur] = (colTotal[cur] ?? 0) + v;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: labelW),
            for (final cur in m.currencies)
              SizedBox(
                width: cellW,
                child: Center(child: Text(cur, style: headerStyle)),
              ),
            const SizedBox(width: 4),
            SizedBox(
              width: 40,
              child: Center(child: Text('Σ', style: headerStyle)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Data rows
        for (final acct in m.accounts) ...[
          Row(
            children: [
              SizedBox(
                width: labelW,
                child: Text(acct, style: headerStyle, overflow: TextOverflow.ellipsis),
              ),
              for (final cur in m.currencies)
                () {
                  final val = m.cells[(acct, cur)] ?? 0;
                  final intensity = m.maxValue > 0
                      ? (val / m.maxValue).clamp(0.0, 1.0)
                      : 0.0;
                  return Container(
                    width: cellW,
                    height: cellH,
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: heatColor(intensity).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: val > 0
                          ? Border.all(
                              color: heatColor(intensity).withValues(alpha: 0.3),
                              width: 0.5,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: val > 0
                        ? Text(
                            compactValueCJK(val),
                            style: cellStyle.copyWith(
                              color: intensity > 0.5
                                  ? Colors.white
                                  : GwpColors.textPrimary,
                            ),
                          )
                        : null,
                  );
                }(),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(
                  compactValueCJK(rowTotal[acct] ?? 0),
                  style: const TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
        ],
        // Column totals row
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: labelW),
            for (final cur in m.currencies)
              SizedBox(
                width: cellW,
                child: Text(
                  compactValueCJK(colTotal[cur] ?? 0),
                  style: const TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 9,
                    color: GwpColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.maxValue});
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '0',
          style: TextStyle(fontSize: 9, color: GwpColors.textMuted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [
                  GwpColors.actionPrimary.withValues(alpha: 0.06),
                  GwpColors.actionPrimary.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          compactValueCJK(maxValue),
          style: const TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontSize: 9,
            color: GwpColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §6  Risk Overview (Concentration + Liquidity)
// ──────────────────────────────────────────────────────────────

class _RiskOverviewSection extends ConsumerWidget {
  const _RiskOverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concAsync = ref.watch(concentrationProvider);
    final liqAsync = ref.watch(liquidityProvider);

    return _SectionCard(
      icon: Icons.shield_outlined,
      iconColor: GwpColors.warning,
      title: '风险概览',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Concentration sub-section ──
          const _SubTitle('集中度分析 (HHI)'),
          concAsync.when(
            loading: () => const _Loading(),
            error: (e, _) => _Error(e),
            data: (m) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _HhiGauge(label: '资产', value: m.assetHhi)),
                    Expanded(child: _HhiGauge(label: '币种', value: m.currencyHhi)),
                    Expanded(child: _HhiGauge(label: '地区', value: m.regionHhi)),
                  ],
                ),
                const SizedBox(height: GwpSpacing.md),
                _InfoRow(
                  'Top 3 占比',
                  '${(m.top3Share * 100).toStringAsFixed(1)}%',
                ),
                if (m.top3Labels.isNotEmpty)
                  _InfoRow('Top 3', m.top3Labels.join(' · ')),
                _InfoRow(
                  '最大持仓',
                  '${m.largestLabel} · ${(m.largestShare * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: GwpSpacing.md),
            child: Divider(height: 1, color: GwpColors.border),
          ),
          // ── Liquidity sub-section ──
          const _SubTitle('流动性分层'),
          liqAsync.when(
            loading: () => const _Loading(),
            error: (e, _) => _Error(e),
            data: (p) {
              if (p.total <= 0) return const _Empty();
              return Column(
                children: [
                  _LiquidityBar(profile: p),
                  const SizedBox(height: GwpSpacing.sm),
                  Row(
                    children: [
                      _LiquidityLegend(
                        color: GwpColors.positive,
                        label: '高',
                        pct: p.highPct,
                        detail: '现金·定存',
                      ),
                      const Spacer(),
                      _LiquidityLegend(
                        color: GwpColors.info,
                        label: '中',
                        pct: p.medPct,
                        detail: '股票·基金·加密',
                      ),
                      const Spacer(),
                      _LiquidityLegend(
                        color: GwpColors.warning,
                        label: '低',
                        pct: p.lowPct,
                        detail: '债券·保险·其他',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HhiGauge extends StatelessWidget {
  const _HhiGauge({required this.label, required this.value});
  final String label;
  final double value; // 0–1

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    // HHI < 0.15 = diversified, 0.15–0.25 = moderate, > 0.25 = concentrated
    final color = value < 0.15
        ? GwpColors.positive
        : value < 0.25
            ? GwpColors.warning
            : GwpColors.negative;
    final statusLabel = value < 0.15 ? '分散' : value < 0.25 ? '适中' : '集中';

    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: value.clamp(0, 1),
                  strokeWidth: 4,
                  backgroundColor: GwpColors.surface3,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '.$pct',
                style: TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LiquidityBar extends StatelessWidget {
  const _LiquidityBar({required this.profile});
  final LiquidityProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            if (profile.highPct > 0)
              Expanded(
                flex: (profile.highPct * 10).round().clamp(1, 1000),
                child: Container(color: GwpColors.positive),
              ),
            if (profile.medPct > 0)
              Expanded(
                flex: (profile.medPct * 10).round().clamp(1, 1000),
                child: Container(color: GwpColors.info),
              ),
            if (profile.lowPct > 0)
              Expanded(
                flex: (profile.lowPct * 10).round().clamp(1, 1000),
                child: Container(color: GwpColors.warning),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiquidityLegend extends StatelessWidget {
  const _LiquidityLegend({
    required this.color,
    required this.label,
    required this.pct,
    required this.detail,
  });

  final Color color;
  final String label;
  final double pct;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$label ${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: const TextStyle(fontSize: 9, color: GwpColors.textMuted),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §7  Health Radar (enhanced with score bars)
// ──────────────────────────────────────────────────────────────

class _HealthRadarSection extends ConsumerWidget {
  const _HealthRadarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthScoreProvider);
    return _SectionCard(
      icon: Icons.radar_outlined,
      iconColor: GwpColors.positive,
      title: '财务健康评分',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _Error(e),
        data: (dims) {
          if (dims.isEmpty) return const _Empty();
          final overall =
              dims.fold<double>(0, (s, d) => s + d.value) / dims.length;
          return Column(
            children: [
              // Radar + overall score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OverallScoreBadge(score: overall),
                  const SizedBox(width: GwpSpacing.md),
                  Expanded(
                    child: GwpRadarChart(dimensions: dims, size: 200),
                  ),
                ],
              ),
              const SizedBox(height: GwpSpacing.lg),
              // Per-dimension bars
              for (var i = 0; i < dims.length; i++) ...[
                _DimensionBar(label: dims[i].label, value: dims[i].value),
                if (i < dims.length - 1)
                  const SizedBox(height: GwpSpacing.xs),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OverallScoreBadge extends StatelessWidget {
  const _OverallScoreBadge({required this.score});
  final double score; // 0–1

  @override
  Widget build(BuildContext context) {
    final scoreInt = (score * 100).round();
    final color = score >= 0.7
        ? GwpColors.positive
        : score >= 0.4
            ? GwpColors.warning
            : GwpColors.negative;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$scoreInt',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '综合分',
              style: TextStyle(fontSize: 9, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.label, required this.value});
  final String label;
  final double value; // 0–1

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final color = value >= 0.7
        ? GwpColors.positive
        : value >= 0.4
            ? GwpColors.warning
            : GwpColors.negative;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                backgroundColor: GwpColors.surface3,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Section wrapper + shared helpers
// ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GwpSpacing.base, GwpSpacing.md, GwpSpacing.base, GwpSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(GwpSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GwpSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GwpColors.textSecondary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GwpColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.error);
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.base),
      child: Text(
        '加载失败: $error',
        style: const TextStyle(color: GwpColors.negative, fontSize: 12),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: const Text(
        '暂无数据',
        style: TextStyle(color: GwpColors.textMuted, fontSize: 12),
      ),
    );
  }
}
