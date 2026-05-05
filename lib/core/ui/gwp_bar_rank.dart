import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A single item in the horizontal ranking bar chart.
class RankItem {
  const RankItem({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}

/// Horizontal bar chart showing a ranked list of items (e.g. asset Top 10).
class GwpBarRank extends StatelessWidget {
  const GwpBarRank({
    super.key,
    required this.items,
    this.maxBars = 10,
    this.barHeight = 22,
    this.onTap,
    this.formatValue,
  });

  final List<RankItem> items;
  final int maxBars;
  final double barHeight;
  final void Function(int index)? onTap;
  final String Function(double value)? formatValue;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GwpColors.textMuted,
              ),
        ),
      );
    }

    final display = items.take(maxBars).toList();
    final maxVal = display.fold<double>(
        0, (prev, item) => item.value > prev ? item.value : prev);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxVal > 0 ? maxVal * 1.15 : 1,
        barGroups: [
          for (var i = 0; i < display.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: display[i].value,
                  color: display[i].color ??
                      GwpColors.actionPrimary.withValues(alpha: 0.7),
                  width: barHeight,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 72,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= display.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    display[idx].label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: GwpColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= display.length) {
                  return const SizedBox.shrink();
                }
                final fmt = formatValue?.call(display[idx].value) ??
                    _compact(display[idx].value);
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    fmt,
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontFeatures: GwpTypo.tabularFigures,
                      fontSize: 10,
                      color: GwpColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: onTap != null,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              onTap?.call(response!.spot!.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => GwpColors.surface3,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final item = display[group.x];
              final fmt = formatValue?.call(item.value) ?? _compact(item.value);
              return BarTooltipItem(
                '${item.label}\n$fmt',
                const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 11,
                  color: GwpColors.textPrimary,
                ),
              );
            },
          ),
        ),
        rotationQuarterTurns: 1, // horizontal bars
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  static String _compact(double val) {
    if (val.abs() >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
    if (val.abs() >= 1e3) return '${(val / 1e3).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }
}
