import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'finance_map_projection.dart';
import 'projected_edge_geometry.dart';
import 'projected_label_layout.dart';
import 'projected_land_surface.dart';
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

    final maxVal = nodes.fold<double>(0, (prev, n) => n.value > prev ? n.value : prev);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final canvasSize = Size(w, h);

          final edgeCoords = <_EdgeCoord>[];
          final activeProjected = <(double, double)>[];
          for (final edge in edges) {
            final geometry = projectEdgeGeometry(
              size: canvasSize,
              fromCoords: regionMetaOf(regionIndex, edge.fromRegion)?.mapCoords,
              toCoords: regionMetaOf(regionIndex, edge.toRegion)?.mapCoords,
              arcLiftFactor: 0.20,
              arcDepthFactor: 0.08,
            );
            if (geometry == null) continue;
            edgeCoords.add(_EdgeCoord(
              geometry: geometry,
              count: edge.channelCount,
              enabled: edge.enabled,
            ));
          }

          final visuals = <_NodeVisual>[];
          final labelSpecs = <ProjectedLabelSpec>[];
          final sorted = [...nodes]..sort((a, b) => b.value.compareTo(a.value));
          final priorityByCode = <String, int>{
            for (var i = 0; i < sorted.length; i++) sorted[i].regionCode: sorted.length - i,
          };
          final topCodes = sorted.take(3).map((n) => n.regionCode).toSet();

          for (final node in nodes) {
            final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
            if (coords == null) continue;
            final projected = FinanceMapProjection.projectPoint(canvasSize, coords);
            final depth = FinanceMapProjection.projectDepth(coords);
            activeProjected.add((projected.dx / w, projected.dy / h));

            final ratio = maxVal > 0 ? node.value / maxVal : 0.5;
            final radius =
                (14.0 + 10.0 * math.log(1 + ratio * 9) / math.ln10) * (0.88 + depth * 0.16);
            final flag = regionFlag(regionIndex, node.regionCode);
            final labelSize = _measureNodePill(node.label);
            labelSpecs.add(
              ProjectedLabelSpec(
                id: node.regionCode,
                center: projected,
                size: labelSize,
                anchorRadius: radius,
                priority: (priorityByCode[node.regionCode] ?? 0) * 100 + node.accountCount,
                keepVisible: topCodes.contains(node.regionCode),
                gap: 6,
                maxRing: 3,
                ringSpacing: 14,
              ),
            );
            visuals.add(_NodeVisual(
              node: node,
              center: projected,
              depth: depth,
              radius: radius,
              flag: flag,
            ));
          }

          final placements = {
            for (final placement in computeProjectedLabelPlacements(canvasSize, labelSpecs, padding: 4))
              placement.id: placement,
          };

          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: canvasSize,
                painter: _MapPainter(
                  edges: edgeCoords,
                  activeProjected: activeProjected,
                  labelPlacements: visuals
                      .map((visual) => _LeaderLine(
                            center: visual.center,
                            placement: placements[visual.node.regionCode],
                          ))
                      .where((line) => line.placement != null && line.placement!.visible)
                      .toList(),
                ),
              ),
              for (final visual in visuals) _buildNodeBubble(context, visual),
              for (final visual in visuals)
                if ((placements[visual.node.regionCode]?.visible ?? false))
                  _buildNodePill(
                    visual.node,
                    visual.depth,
                    placements[visual.node.regionCode]!,
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNodeBubble(BuildContext context, _NodeVisual visual) {
    return Positioned(
      left: visual.center.dx - visual.radius,
      top: visual.center.dy - visual.radius,
      child: GestureDetector(
        onTap: onNodeTap != null ? () => onNodeTap!(visual.node.regionCode) : null,
        child: Container(
          width: visual.radius * 2,
          height: visual.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GwpColors.actionPrimary.withValues(alpha: 0.16 + visual.depth * 0.10),
            border: Border.all(
              color: GwpColors.actionPrimary.withValues(alpha: 0.48 + visual.depth * 0.20),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            visual.flag,
            style: TextStyle(fontSize: visual.radius * 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildNodePill(
    MapNode node,
    double depth,
    ProjectedLabelPlacement placement,
  ) {
    return Positioned(
      left: placement.rect.left,
      top: placement.rect.top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: GwpColors.surface2.withValues(alpha: 0.80 + depth * 0.10),
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
      ),
    );
  }
}

class _NodeVisual {
  const _NodeVisual({
    required this.node,
    required this.center,
    required this.depth,
    required this.radius,
    required this.flag,
  });

  final MapNode node;
  final Offset center;
  final double depth;
  final double radius;
  final String flag;
}

class _LeaderLine {
  const _LeaderLine({required this.center, required this.placement});

  final Offset center;
  final ProjectedLabelPlacement? placement;
}

class _EdgeCoord {
  const _EdgeCoord({
    required this.geometry,
    this.count = 1,
    this.enabled = true,
  });

  final ProjectedEdgeGeometry geometry;
  final int count;
  final bool enabled;
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.edges,
    required this.activeProjected,
    required this.labelPlacements,
  });

  final List<_EdgeCoord> edges;
  final List<(double, double)> activeProjected;
  final List<_LeaderLine> labelPlacements;
  static final _surface = ProjectedLandSurface.forGrid(cols: 48, rows: 24);

  @override
  void paint(Canvas canvas, Size size) {
    _paintContinentDots(canvas, size);
    _paintEdges(canvas);
    _paintLeaderLines(canvas);
  }

  void _paintContinentDots(Canvas canvas, Size size) {
    for (var r = 0; r < _surface.rows; r++) {
      for (var c = 0; c < _surface.cols; c++) {
        if (!_surface.bitmap[r][c]) continue;

        final nx = (c + 0.5) / _surface.cols;
        final ny = (r + 0.5) / _surface.rows;
        final projected = Offset(nx * size.width, ny * size.height);

        var isHot = false;
        for (final active in activeProjected) {
          final dx = nx - active.$1;
          final dy = ny - active.$2;
          if (dx * dx + dy * dy < 0.010) {
            isHot = true;
            break;
          }
        }

        canvas.drawCircle(
          projected,
          isHot ? 1.2 : 1.0,
          Paint()
            ..color = (isHot ? GwpColors.actionPrimary : GwpColors.border)
                .withValues(alpha: isHot ? 0.22 : 0.16)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _paintEdges(Canvas canvas) {
    for (final edge in edges) {
      final depth = edge.geometry.depth;
      final path = edge.geometry.buildPath();

      canvas.drawPath(
        path,
        Paint()
          ..color = (edge.enabled ? GwpColors.actionPrimary : GwpColors.textMuted)
              .withValues(alpha: edge.enabled ? 0.18 + depth * 0.18 : 0.12 + depth * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge.geometry.recommendedStrokeWidth(
            count: edge.count,
            base: 0.75,
            countFactor: 0.32,
            depthBase: 0.84,
            depthFactor: 0.24,
            min: 0.75,
            max: 2.4,
          ),
      );
    }
  }

  void _paintLeaderLines(Canvas canvas) {
    for (final leader in labelPlacements) {
      final placement = leader.placement;
      if (placement == null || !placement.showLeaderLine) continue;
      canvas.drawLine(
        leader.center,
        placement.attachPoint,
        Paint()
          ..color = GwpColors.textMuted.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      edges.length != old.edges.length ||
      activeProjected.length != old.activeProjected.length ||
      labelPlacements.length != old.labelPlacements.length ||
      !_coordListEquals(edges, old.edges);
}

bool _coordListEquals(List<_EdgeCoord> a, List<_EdgeCoord> b) {
  if (identical(a, b)) return true;
  final n = a.length;
  if (n != b.length) return false;
  for (var i = 0; i < n; i++) {
    if (a[i].geometry.from != b[i].geometry.from ||
        a[i].geometry.to != b[i].geometry.to ||
        a[i].geometry.control != b[i].geometry.control ||
        a[i].geometry.fromDepth != b[i].geometry.fromDepth ||
        a[i].geometry.toDepth != b[i].geometry.toDepth ||
        a[i].count != b[i].count ||
        a[i].enabled != b[i].enabled) {
      return false;
    }
  }
  return true;
}

Size _measureNodePill(String label) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        fontFamily: GwpTypo.monoFont,
        fontFeatures: GwpTypo.tabularFigures,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: GwpColors.textPrimary,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return Size(painter.width + 8, painter.height + 2);
}
