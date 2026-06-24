import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Inline mini area/line chart for sparkline display in list rows and hero cards.
class CofferMiniChart extends StatelessWidget {
  const CofferMiniChart({
    super.key,
    required this.data,
    this.width = 80,
    this.height = 32,
    this.color,
    this.showArea = true,
    this.strokeWidth = 1.5,
  });

  final List<double> data;
  final double width;
  final double height;
  final Color? color;
  final bool showArea;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);

    final isUp = data.last >= data.first;
    final lineColor = color ?? (isUp ? CofferColors.positive : CofferColors.negative);

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: lineColor,
              barWidth: strokeWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: showArea
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.25),
                          lineColor.withValues(alpha: 0.0),
                        ],
                      ),
                    )
                  : BarAreaData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
