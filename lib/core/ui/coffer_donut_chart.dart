import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A single segment in a donut chart.
class ChartSegment {
  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Donut/ring chart with center label, built on fl_chart PieChart.
class CofferDonutChart extends StatelessWidget {
  const CofferDonutChart({
    super.key,
    required this.segments,
    this.centerLabel,
    this.centerSubLabel,
    this.size = 160,
    this.strokeWidth = 24,
    this.onSegmentTap,
  });

  final List<ChartSegment> segments;
  final String? centerLabel;
  final String? centerSubLabel;
  final double size;
  final double strokeWidth;
  final void Function(int index)? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < segments.length; i++)
                  PieChartSectionData(
                    value: segments[i].value,
                    color: segments[i].color,
                    radius: strokeWidth,
                    showTitle: false,
                  ),
              ],
              centerSpaceRadius: size / 2 - strokeWidth - 4,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                enabled: onSegmentTap != null,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent &&
                      response?.touchedSection != null) {
                    final idx =
                        response!.touchedSection!.touchedSectionIndex;
                    if (idx >= 0) onSegmentTap?.call(idx);
                  }
                },
              ),
            ),
            duration: const Duration(milliseconds: 300),
          ),
          if (centerLabel != null || centerSubLabel != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (centerLabel != null)
                  Text(
                    centerLabel!,
                    style: TextStyle(
                      fontFamily: CofferTypo.monoFont,
                      fontFeatures: CofferTypo.tabularFigures,
                      fontSize: math.min(size / 8, 18),
                      fontWeight: FontWeight.w700,
                      color: CofferColors.textPrimary,
                    ),
                  ),
                if (centerSubLabel != null)
                  Text(
                    centerSubLabel!,
                    style: TextStyle(
                      fontSize: math.min(size / 12, 11),
                      color: CofferColors.textMuted,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
