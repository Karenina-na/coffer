import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'region_meta.dart';

export 'region_meta.dart' show RegionIndex;

/// A node on the global account map, representing one sovereignty region.
class MapNode {
  const MapNode({
    required this.regionCode,
    required this.label,
    required this.value,
    this.accountCount = 0,
  });

  final String regionCode;
  final String label; // formatted value string
  final double value; // total market value (display-only double)
  final int accountCount;
}

/// An edge on the global account map, representing a cross-region channel link.
class MapEdge {
  const MapEdge({
    required this.fromRegion,
    required this.toRegion,
    this.channelCount = 1,
    this.enabled = true,
  });

  final String fromRegion;
  final String toRegion;
  final int channelCount;
  final bool enabled;
}

/// A simplified world map with positioned account nodes and channel edges.
///
/// Used in the dashboard to visualise the global distribution of accounts
/// and cross-region transfer channels.
class GwpNodeMap extends StatelessWidget {
  const GwpNodeMap({
    super.key,
    required this.nodes,
    required this.regionIndex,
    this.edges = const [],
    this.onNodeTap,
    this.height = 220,
  });

  final List<MapNode> nodes;
  final RegionIndex regionIndex;
  final List<MapEdge> edges;
  final void Function(String regionCode)? onNodeTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '暂无账户数据',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GwpColors.textMuted,
                ),
          ),
        ),
      );
    }

    // Calculate max value for node sizing
    final maxVal = nodes.fold<double>(
        0, (prev, n) => n.value > prev ? n.value : prev);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Build positioned edges and nodes
          final edgeCoords = <_EdgeCoord>[];
          for (final edge in edges) {
            final from = regionMetaOf(regionIndex, edge.fromRegion)?.mapCoords;
            final to = regionMetaOf(regionIndex, edge.toRegion)?.mapCoords;
            if (from == null || to == null) continue;
            edgeCoords.add(_EdgeCoord(
              from: Offset(from.$1 * w, from.$2 * h),
              to: Offset(to.$1 * w, to.$2 * h),
              count: edge.channelCount,
              enabled: edge.enabled,
            ));
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Simplified continent outlines + edge lines
              CustomPaint(
                size: Size(w, h),
                painter: _MapPainter(edges: edgeCoords),
              ),
              // Account nodes
              for (final node in nodes)
                _buildNode(context, node, w, h, maxVal, regionIndex),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    MapNode node,
    double w,
    double h,
    double maxVal,
    RegionIndex regionIndex,
  ) {
    final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
    if (coords == null) return const SizedBox.shrink();

    final cx = coords.$1 * w;
    final cy = coords.$2 * h;

    // Radius proportional to log of value
    final ratio = maxVal > 0 ? node.value / maxVal : 0.5;
    final radius = 14.0 + 10.0 * math.log(1 + ratio * 9) / math.ln10;

    final flag = regionFlag(regionIndex, node.regionCode);

    return Positioned(
      left: cx - radius,
      top: cy - radius,
      child: GestureDetector(
        onTap: onNodeTap != null ? () => onNodeTap!(node.regionCode) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GwpColors.actionPrimary.withValues(alpha: 0.2),
                border: Border.all(
                  color: GwpColors.actionPrimary.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                flag,
                style: TextStyle(fontSize: radius * 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: GwpColors.surface2.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.label,
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeCoord {
  const _EdgeCoord({
    required this.from,
    required this.to,
    this.count = 1,
    this.enabled = true,
  });
  final Offset from;
  final Offset to;
  final int count;
  final bool enabled;
}

/// Paints simplified continent outlines and channel edge bezier curves.
class _MapPainter extends CustomPainter {
  _MapPainter({required this.edges});

  final List<_EdgeCoord> edges;

  @override
  void paint(Canvas canvas, Size size) {
    _paintContinentDots(canvas, size);
    _paintEdges(canvas);
  }

  void _paintContinentDots(Canvas canvas, Size size) {
    // Draw a subtle dot grid to suggest a world map
    final dotPaint = Paint()
      ..color = GwpColors.border.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Simplified continent regions as rectangular dot clusters
    final continents = <(double, double, double, double)>[
      // (xFrac, yFrac, wFrac, hFrac)
      (0.08, 0.20, 0.22, 0.45), // Americas
      (0.40, 0.15, 0.18, 0.50), // Europe + Africa
      (0.62, 0.20, 0.28, 0.55), // Asia + Oceania
    ];

    for (final c in continents) {
      final startX = c.$1 * size.width;
      final startY = c.$2 * size.height;
      final endX = (c.$1 + c.$3) * size.width;
      final endY = (c.$2 + c.$4) * size.height;

      for (var x = startX; x < endX; x += 12) {
        for (var y = startY; y < endY; y += 12) {
          canvas.drawCircle(Offset(x, y), 1, dotPaint);
        }
      }
    }
  }

  void _paintEdges(Canvas canvas) {
    for (final edge in edges) {
      final paint = Paint()
        ..color = edge.enabled
            ? GwpColors.actionPrimary.withValues(alpha: 0.5)
            : GwpColors.textMuted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (0.8 + edge.count * 0.4).clamp(0.8, 3.0);

      // Bezier curve with control point above the midpoint
      final mid = (edge.from + edge.to) / 2;
      final dist = (edge.from - edge.to).distance;
      final controlY = mid.dy - dist * 0.25;
      final control = Offset(mid.dx, controlY);

      final path = Path()
        ..moveTo(edge.from.dx, edge.from.dy)
        ..quadraticBezierTo(control.dx, control.dy, edge.to.dx, edge.to.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      edges.length != old.edges.length ||
      _coordListEquals(edges, old.edges) == false;
}

bool _coordListEquals(List<_EdgeCoord> a, List<_EdgeCoord> b) {
  if (identical(a, b)) return true;
  final n = a.length;
  if (n != b.length) return false;
  for (var i = 0; i < n; i++) {
    if (a[i].from != b[i].from || a[i].to != b[i].to) return false;
  }
  return true;
}
