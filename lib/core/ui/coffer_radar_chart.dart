import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A single dimension on the radar chart.
class RadarDimension {
  const RadarDimension({required this.label, required this.value});

  /// Display label for this axis (e.g. "分散度").
  final String label;

  /// Score in the range 0.0 – 1.0 (will be displayed as 0 – 100).
  final double value;
}

/// Five-dimension radar chart for the financial health score model.
class CofferRadarChart extends StatelessWidget {
  const CofferRadarChart({
    super.key,
    required this.dimensions,
    this.size = 200,
    this.fillColor,
    this.borderColor,
  });

  final List<RadarDimension> dimensions;
  final double size;
  final Color? fillColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            '暂无评分数据',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CofferColors.textMuted,
                ),
          ),
        ),
      );
    }

    final border = borderColor ?? CofferColors.actionPrimary;
    final fill = fillColor ?? CofferColors.actionPrimary.withValues(alpha: 0.2);

    return SizedBox(
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(
            fontSize: 8,
            color: CofferColors.textMuted,
          ),
          tickBorderData: BorderSide(
            color: CofferColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
          gridBorderData: BorderSide(
            color: CofferColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
          radarBorderData: BorderSide(
            color: CofferColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: CofferColors.textSecondary,
          ),
          getTitle: (index, angle) {
            if (index < 0 || index >= dimensions.length) {
              return RadarChartTitle(text: '');
            }
            final d = dimensions[index];
            final score = (d.value * 100).round();
            return RadarChartTitle(text: '${d.label}\n$score');
          },
          dataSets: [
            RadarDataSet(
              dataEntries: [
                for (final d in dimensions)
                  RadarEntry(value: (d.value * 100).clamp(0, 100)),
              ],
              fillColor: fill,
              borderColor: border,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
