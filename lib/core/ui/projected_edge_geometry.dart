import 'package:flutter/material.dart';

import 'finance_map_projection.dart';

class ProjectedEdgeGeometry {
  const ProjectedEdgeGeometry({
    required this.from,
    required this.to,
    required this.control,
    required this.fromDepth,
    required this.toDepth,
  });

  final Offset from;
  final Offset to;
  final Offset control;
  final double fromDepth;
  final double toDepth;

  double get depth => (fromDepth + toDepth) * 0.5;
  double get distance => (from - to).distance;

  Path buildPath() {
    return Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  double recommendedStrokeWidth({
    required int count,
    required double base,
    required double countFactor,
    required double depthBase,
    required double depthFactor,
    required double min,
    required double max,
  }) {
    return ((base + count * countFactor) * (depthBase + depth * depthFactor))
        .clamp(min, max);
  }

  double recommendedTerminalRadius({
    required double strokeWidth,
    required double base,
    required double depthFactor,
  }) {
    return strokeWidth * (base + depth * depthFactor);
  }
}

ProjectedEdgeGeometry? projectEdgeGeometry({
  required Size size,
  required (double, double)? fromCoords,
  required (double, double)? toCoords,
  double arcLiftFactor = 0.20,
  double arcDepthFactor = 0.08,
  double heightLiftFactor = 0.0,
  double heightDepthFactor = 0.0,
}) {
  if (fromCoords == null || toCoords == null) return null;

  final from = FinanceMapProjection.projectPoint(size, fromCoords);
  final to = FinanceMapProjection.projectPoint(size, toCoords);
  final fromDepth = FinanceMapProjection.projectDepth(fromCoords);
  final toDepth = FinanceMapProjection.projectDepth(toCoords);
  final depth = (fromDepth + toDepth) * 0.5;
  final mid = (from + to) / 2;
  final distance = (from - to).distance;
  final controlLift = distance * (arcLiftFactor + (1 - depth) * arcDepthFactor) +
      size.height * (heightLiftFactor + (1 - depth) * heightDepthFactor);

  return ProjectedEdgeGeometry(
    from: from,
    to: to,
    control: Offset(mid.dx, mid.dy - controlLift),
    fromDepth: fromDepth,
    toDepth: toDepth,
  );
}
