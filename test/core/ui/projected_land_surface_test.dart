import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/ui/finance_map_projection.dart';
import 'package:coffer/core/ui/projected_land_surface.dart';

void main() {
  group('containsRawLand', () {
    test('hits major land areas and misses typical ocean areas', () {
      expect(containsRawLand(0.24, 0.32), isTrue);
      expect(containsRawLand(0.50, 0.24), isTrue);
      expect(containsRawLand(0.78, 0.31), isTrue);
      expect(containsRawLand(0.84, 0.73), isTrue);

      expect(containsRawLand(0.42, 0.35), isFalse);
      expect(containsRawLand(0.10, 0.45), isFalse);
      expect(containsRawLand(0.66, 0.55), isFalse);
      expect(containsRawLand(0.50, 0.90), isFalse);
    });

    test('out-of-bounds coords miss', () {
      expect(containsRawLand(-0.1, 0.5), isFalse);
      expect(containsRawLand(1.1, 0.5), isFalse);
      expect(containsRawLand(0.5, -0.1), isFalse);
      expect(containsRawLand(0.5, 1.1), isFalse);
    });
  });

  group('ProjectedLandSurface', () {
    test('land cell count remains stable for hero grid', () {
      final surface = ProjectedLandSurface.forGrid(cols: 88, rows: 42);
      expect(surface.cellCount(), inInclusiveRange(1500, 1800));
    });

    test('projected financial centers still hit land', () {
      final surface = ProjectedLandSurface.forGrid(cols: 88, rows: 42);
      final london = FinanceMapProjection.projectPoint(const Size(1, 1), ((179.8724) / 360, (90 - 51.5072) / 180));
      final newYork = FinanceMapProjection.projectPoint(const Size(1, 1), ((180 - 74.0060) / 360, (90 - 40.7128) / 180));
      final singapore = FinanceMapProjection.projectPoint(const Size(1, 1), ((180 + 103.8198) / 360, (90 - 1.3521) / 180));

      expect(surface.containsProjected(london.dx, london.dy), isTrue);
      expect(surface.containsProjected(newYork.dx, newYork.dy), isTrue);
      expect(surface.containsProjected(singapore.dx, singapore.dy), isTrue);
    });

    test('projected ocean areas still miss land', () {
      final surface = ProjectedLandSurface.forGrid(cols: 88, rows: 42);
      expect(surface.containsProjected(0.10, 0.78), isFalse);
      expect(surface.containsProjected(0.52, 0.86), isFalse);
    });

    test('different grid sizes remain directionally stable', () {
      final coarse = ProjectedLandSurface.forGrid(cols: 48, rows: 24);
      final fine = ProjectedLandSurface.forGrid(cols: 88, rows: 42);
      final london = FinanceMapProjection.projectPoint(const Size(1, 1), ((179.8724) / 360, (90 - 51.5072) / 180));
      final pacific = const (0.10, 0.78);

      expect(coarse.containsProjected(london.dx, london.dy), isTrue);
      expect(fine.containsProjected(london.dx, london.dy), isTrue);
      expect(coarse.containsProjected(pacific.$1, pacific.$2), isFalse);
      expect(fine.containsProjected(pacific.$1, pacific.$2), isFalse);
    });
  });
}
