import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A single-row heat bar indicating magnitude within a range.
///
/// Useful for showing daily change intensity in exchange-rate lists.
/// The filled portion uses a gradient from neutral to the semantic color
/// (positive = green, negative = red), and its width represents the
/// absolute value relative to [maxAbsValue].
class CofferHeatStrip extends StatelessWidget {
  const CofferHeatStrip({
    super.key,
    required this.value,
    this.maxAbsValue = 1.0,
    this.label,
    this.height = 6,
    this.width = double.infinity,
    this.borderRadius = 3,
  });

  /// The data value (e.g. daily change %). Positive fills green, negative red.
  final double value;

  /// The maximum absolute value that maps to a fully-filled bar.
  final double maxAbsValue;

  /// Optional label displayed to the right of the bar.
  final String? label;

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ratio = maxAbsValue > 0
        ? (value.abs() / maxAbsValue).clamp(0.0, 1.0)
        : 0.0;
    final isPositive = value >= 0;
    final barColor =
        isPositive ? CofferColors.positive : CofferColors.negative;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: _HeatStripPainter(
                  ratio: ratio,
                  barColor: barColor,
                  trackColor: CofferColors.surface3,
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: TextStyle(
              fontFamily: CofferTypo.monoFont,
              fontFeatures: CofferTypo.tabularFigures,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: barColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeatStripPainter extends CustomPainter {
  _HeatStripPainter({
    required this.ratio,
    required this.barColor,
    required this.trackColor,
  });

  final double ratio;
  final Color barColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, trackPaint);

    if (ratio > 0) {
      final barWidth = size.width * ratio;
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            barColor.withValues(alpha: 0.3),
            barColor.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(0, 0, barWidth, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, size.height), barPaint);
    }
  }

  @override
  bool shouldRepaint(_HeatStripPainter old) =>
      old.ratio != ratio || old.barColor != barColor;
}
