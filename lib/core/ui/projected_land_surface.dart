import 'package:flutter/material.dart';

import 'dashboard_land_data.dart';
import 'finance_map_projection.dart';

@immutable
class ProjectedLandSurface {
  const ProjectedLandSurface._({
    required this.cols,
    required this.rows,
    required this.bitmap,
  });

  final int cols;
  final int rows;
  final List<List<bool>> bitmap;

  static final Map<String, ProjectedLandSurface> _cache = {};

  static ProjectedLandSurface forGrid({required int cols, required int rows}) {
    final key = '$cols x $rows';
    return _cache.putIfAbsent(key, () => _build(cols: cols, rows: rows));
  }

  bool containsProjected(double px, double py) {
    if (px < 0 || px > 1 || py < 0 || py > 1) return false;
    final c = (px * cols).floor().clamp(0, cols - 1);
    final r = (py * rows).floor().clamp(0, rows - 1);
    return bitmap[r][c];
  }

  int cellCount() {
    var count = 0;
    for (final row in bitmap) {
      for (final isLand in row) {
        if (isLand) count++;
      }
    }
    return count;
  }

  static ProjectedLandSurface _build({required int cols, required int rows}) {
    final bitmap = List.generate(rows, (_) => List.filled(cols, false));
    final sampleCols = cols * 3;
    final sampleRows = rows * 3;
    const unitSize = Size(1, 1);

    for (var r = 0; r < sampleRows; r++) {
      for (var c = 0; c < sampleCols; c++) {
        final nx = (c + 0.5) / sampleCols;
        final ny = (r + 0.5) / sampleRows;
        if (!containsRawLand(nx, ny)) continue;

        final projected = FinanceMapProjection.projectPoint(unitSize, (nx, ny));
        final pc = (projected.dx * cols).floor().clamp(0, cols - 1);
        final pr = (projected.dy * rows).floor().clamp(0, rows - 1);
        bitmap[pr][pc] = true;
      }
    }

    return ProjectedLandSurface._(
      cols: cols,
      rows: rows,
      bitmap: _fillBitmapGaps(bitmap, cols: cols, rows: rows),
    );
  }
}

bool containsRawLand(double px, double py) {
  for (var i = 0; i < kDashboardHeroLandPolygons.length; i++) {
    final bounds = kDashboardHeroLandBounds[i];
    if (px < bounds.$1 || px > bounds.$3 || py < bounds.$2 || py > bounds.$4) {
      continue;
    }
    if (_pointInPolygon(px, py, kDashboardHeroLandPolygons[i])) {
      return true;
    }
  }
  return false;
}

List<List<bool>> _fillBitmapGaps(
  List<List<bool>> bitmap, {
  required int cols,
  required int rows,
}) {
  final expanded = List.generate(
    rows,
    (r) => List<bool>.from(bitmap[r]),
  );

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (bitmap[r][c]) continue;
      var neighbors = 0;
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final rr = r + dr;
          final cc = c + dc;
          if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) continue;
          if (bitmap[rr][cc]) neighbors++;
        }
      }
      if (neighbors >= 4) expanded[r][c] = true;
    }
  }

  return expanded;
}

bool _pointInPolygon(double px, double py, List<(double, double)> polygon) {
  var inside = false;
  var j = polygon.length - 1;
  for (var i = 0; i < polygon.length; i++) {
    final xi = polygon[i].$1;
    final yi = polygon[i].$2;
    final xj = polygon[j].$1;
    final yj = polygon[j].$2;
    if ((yi > py) != (yj > py) &&
        px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}
