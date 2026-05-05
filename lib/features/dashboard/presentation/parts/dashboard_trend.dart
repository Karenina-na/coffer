part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// D. Net Worth Trend — delta header + chart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TrendSection extends ConsumerWidget {
  const _TrendSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _TrendBody();
  }
}

class _TrendBody extends ConsumerWidget {
  const _TrendBody();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deltaAsync = ref.watch(trendDeltaProvider);
    final range = ref.watch(trendRangeProvider);
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.sm),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 4, right: 0, top: 2, bottom: GwpSpacing.xs),
            child: Row(
              children: [
                Text(
                  '净资产趋势',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GwpColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _RangeChips(
                  selected: range,
                  onSelected: (v) =>
                      ref.read(trendRangeProvider.notifier).set(v),
                ),
              ],
            ),
          ),
          deltaAsync.when(
            loading: () => const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                  color: GwpColors.actionPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox(
              height: 140,
              child: Center(
                child: Icon(Icons.error_outline, color: GwpColors.textMuted),
              ),
            ),
            data: (delta) {
              if (!delta.hasEnoughData) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      '数据不足，估值事件记录后将显示趋势',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GwpColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrendHeaderStats(delta: delta),
                  const SizedBox(height: GwpSpacing.xs),
                  SizedBox(height: 120, child: _TrendChart(delta: delta)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendHeaderStats extends StatelessWidget {
  const _TrendHeaderStats({required this.delta});
  final TrendDelta delta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _KvStat(
            label: '期末',
            value: _compactNum(delta.endValue),
            emphasize: true,
          ),
        ),
        Expanded(
          child: _KvStat(
            label: '区间变动',
            value:
                '${delta.isUp ? '+' : ''}${(delta.deltaPct * 100).toStringAsFixed(2)}%',
            color: delta.isUp ? GwpColors.positive : GwpColors.negative,
          ),
        ),
      ],
    );
  }
}

class _KvStat extends StatelessWidget {
  const _KvStat({
    required this.label,
    required this.value,
    this.color,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontSize: emphasize ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? GwpColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.delta});
  final TrendDelta delta;

  @override
  Widget build(BuildContext context) {
    final points = delta.points;
    final isUp = delta.isUp;
    final lineColor = isUp ? GwpColors.positive : GwpColors.negative;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final range = delta.maxValue - delta.minValue;
    final paddedMin = delta.minValue - range * 0.1;
    final paddedMax = delta.maxValue + range * 0.1;
    final refValue = delta.startValue;

    return LineChart(
      LineChartData(
        minY: range > 0 ? paddedMin : delta.minValue - 1,
        maxY: range > 0 ? paddedMax : delta.maxValue + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 0 ? range / 3 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: GwpColors.border.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _compactNum(value),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 9,
                      color: GwpColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: refValue,
              color: GwpColors.textMuted.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [4, 3],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => GwpColors.surface3,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt().clamp(0, points.length - 1);
              final p = points[idx];
              final d = p.date;
              final dateStr = '${d.month}/${d.day}';
              return LineTooltipItem(
                '$dateStr\n${_compactNum(p.value)}',
                TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 11,
                  color: lineColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (_, spots) => spots
              .map((_) => TouchedSpotIndicatorData(
                    FlLine(
                      color: lineColor.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dashArray: [3, 2],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: lineColor,
                        strokeWidth: 0,
                      ),
                    ),
                  ))
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.2),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

String _compactNum(double val) {
  if (val.abs() >= 1e6) return '${(val / 1e6).toStringAsFixed(2)}M';
  if (val.abs() >= 1e3) return '${(val / 1e3).toStringAsFixed(1)}K';
  return val.toStringAsFixed(0);
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelected});
  final int selected;
  final void Function(int days) onSelected;

  static const _options = [
    (7, '7D'),
    (30, '1M'),
    (90, '3M'),
    (365, '1Y'),
    (0, 'ALL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (days, label) in _options)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () => onSelected(days),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected == days
                      ? GwpColors.actionPrimary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selected == days ? FontWeight.w700 : FontWeight.w500,
                    color: selected == days
                        ? GwpColors.actionPrimary
                        : GwpColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
