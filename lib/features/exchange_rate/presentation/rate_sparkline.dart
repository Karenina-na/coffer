import 'package:flutter/material.dart';

import '../../../core/ui/design_tokens.dart';

/// 轻量折线图：normalize 到 y=[0,1]，一次描边，无依赖。
///
/// - `points` 必须至少 2 个点才能成线；否则绘制水平虚线以示占位。
/// - `isUp` 决定描边颜色（涨/跌）。
class RateSparkline extends StatelessWidget {
  const RateSparkline({
    super.key,
    required this.points,
    required this.isUp,
    this.height = 32,
    this.width = 80,
  });

  final List<double> points;
  final bool isUp;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isUp ? CofferColors.positive : scheme.error;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparkPainter(
          points: points,
          color: color,
          flatColor: scheme.outlineVariant,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.points,
    required this.color,
    required this.flatColor,
  });

  final List<double> points;
  final Color color;
  final Color flatColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      // 画一条虚线作为占位
      final paint = Paint()
        ..color = flatColor
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final y = size.height / 2;
      const dash = 4.0;
      const gap = 3.0;
      double x = 0;
      while (x < size.width) {
        final x2 = (x + dash).clamp(0.0, size.width);
        canvas.drawLine(Offset(x, y), Offset(x2, y), paint);
        x += dash + gap;
      }
      return;
    }
    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();
    final denom = range < 1e-12 ? 1.0 : range;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final normalized = (points[i] - minV) / denom;
      // y 翻转：大值在上
      final y = size.height * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.points != points || old.color != color;
}
