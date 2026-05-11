import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/ui/finance_map_projection.dart';

void main() {
  group('FinanceMapProjection model', () {
    test('default model exposes named finance zones and frame params', () {
      expect(FinanceMapProjection.defaultModel.frame.hemisphereWidth, closeTo(0.94, 1e-9));
      expect(
        FinanceMapProjection.defaultModel.zones.map((z) => z.name),
        orderedEquals([
          'northAtlanticCompression',
          'canadaNorthCompression',
          'europeBasin',
          'northAmericaCorridor',
          'eastAsiaBasin',
          'southeastAsiaSupport',
        ]),
      );
    });
  });

  group('projectPoint', () {
    const size = Size(360, 196);

    test('center sits higher than lateral points at the same latitude', () {
      final left = FinanceMapProjection.projectPoint(size, (0.1, 0.4));
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.4));
      final right = FinanceMapProjection.projectPoint(size, (0.9, 0.4));
      expect(center.dy, lessThan(left.dy));
      expect(center.dy, lessThan(right.dy));
    });

    test('projected x remains monotonic', () {
      final left = FinanceMapProjection.projectPoint(size, (0.1, 0.5));
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.5));
      final right = FinanceMapProjection.projectPoint(size, (0.9, 0.5));
      expect(left.dx, lessThan(center.dx));
      expect(center.dx, lessThan(right.dx));
    });

    test('projected points remain in bounds', () {
      final points = [
        FinanceMapProjection.projectPoint(size, (0.0, 0.0)),
        FinanceMapProjection.projectPoint(size, (1.0, 0.0)),
        FinanceMapProjection.projectPoint(size, (0.0, 1.0)),
        FinanceMapProjection.projectPoint(size, (1.0, 1.0)),
      ];
      for (final point in points) {
        expect(point.dx, inInclusiveRange(0.0, size.width));
        expect(point.dy, inInclusiveRange(0.0, size.height));
      }
    });

    test('north remains above south', () {
      final north = FinanceMapProjection.projectPoint(size, (0.5, 0.25));
      final south = FinanceMapProjection.projectPoint(size, (0.5, 0.75));
      expect(north.dy, lessThan(south.dy));
    });

    test('edge sits lower than center for dome depth', () {
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.35));
      final edge = FinanceMapProjection.projectPoint(size, (0.0, 0.35));
      expect(center.dy, lessThan(edge.dy));
    });
  });

  group('warpCoords and projectDepth', () {
    test('finance belts reshape local horizontal spacing', () {
      final europeLeft = FinanceMapProjection.warpCoords((0.49, 0.275)).$1;
      final europeRight = FinanceMapProjection.warpCoords((0.58, 0.275)).$1;
      expect(europeRight - europeLeft, greaterThan(0.09));

      final eastAsiaLeft = FinanceMapProjection.warpCoords((0.73, 0.315)).$1;
      final eastAsiaRight = FinanceMapProjection.warpCoords((0.80, 0.315)).$1;
      expect(eastAsiaRight - eastAsiaLeft, isNot(closeTo(0.07, 1e-3)));
    });

    test('depth is higher at center and north', () {
      expect(
        FinanceMapProjection.projectDepth((0.5, 0.4)),
        greaterThan(FinanceMapProjection.projectDepth((0.0, 0.4))),
      );
      expect(
        FinanceMapProjection.projectDepth((0.5, 0.2)),
        greaterThan(FinanceMapProjection.projectDepth((0.5, 0.8))),
      );
    });

    test('depth stays within 0..1', () {
      for (final sample in [
        (0.0, 0.0),
        (0.5, 0.5),
        (1.0, 1.0),
        (0.25, 0.75),
      ]) {
        final depth = FinanceMapProjection.projectDepth(sample);
        expect(depth, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
