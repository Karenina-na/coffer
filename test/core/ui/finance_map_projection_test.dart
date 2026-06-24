import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/ui/finance_map_projection.dart';

void main() {
  group('FinanceProjectionFrame', () {
    test('frame exposes essential params', () {
      expect(FinanceMapProjection.frame.hemisphereWidthLeft, greaterThan(1.0));
      expect(FinanceMapProjection.frame.hemisphereWidthRight, lessThan(1.05));
      expect(FinanceMapProjection.frame.northSpan, inInclusiveRange(0.5, 0.6));
      expect(FinanceMapProjection.frame.mapSideInset, greaterThan(0));
    });
  });

  group('projectPoint', () {
    const size = Size(360, 196);

    test('center sits lower than lateral points at same latitude', () {
      final left = FinanceMapProjection.projectPoint(size, (0.1, 0.4));
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.4));
      final right = FinanceMapProjection.projectPoint(size, (0.9, 0.4));
      expect(center.dy, greaterThan(left.dy));
      expect(center.dy, greaterThan(right.dy));
    });

    test('projected x remains monotonic', () {
      final left = FinanceMapProjection.projectPoint(size, (0.1, 0.5));
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.5));
      final right = FinanceMapProjection.projectPoint(size, (0.9, 0.5));
      expect(left.dx, lessThan(center.dx));
      expect(center.dx, lessThan(right.dx));
    });

    test('projected Y remains in bounds, X may crop at edges', () {
      final points = [
        FinanceMapProjection.projectPoint(size, (0.0, 0.0)),
        FinanceMapProjection.projectPoint(size, (1.0, 0.0)),
        FinanceMapProjection.projectPoint(size, (0.0, 1.0)),
        FinanceMapProjection.projectPoint(size, (1.0, 1.0)),
      ];
      for (final point in points) {
        expect(point.dy, inInclusiveRange(0.0, size.height));
      }
    });

    test('north remains above south', () {
      final north = FinanceMapProjection.projectPoint(size, (0.5, 0.25));
      final south = FinanceMapProjection.projectPoint(size, (0.5, 0.75));
      expect(north.dy, lessThan(south.dy));
    });

    test('edge sits higher than center (hemisphere curvature)', () {
      final center = FinanceMapProjection.projectPoint(size, (0.5, 0.35));
      final edge = FinanceMapProjection.projectPoint(size, (0.0, 0.35));
      expect(edge.dy, lessThan(center.dy));
    });
  });

  group('projectDepth', () {
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

  group('display transform', () {
    test('negative offsetY shifts map up', () {
      // frame has displayOffsetY = -0.08
      final north = FinanceMapProjection.projectPoint(const Size(360, 300), (0.5, 0.0));
      // With negative offset, northernmost point may shift above canvas
      expect(north.dy, lessThan(30));
    });
  });

  group('projectCryptoShelf', () {
    test('positions nodes around crypto hub', () {
      const size = Size(360, 300);
      final a = FinanceMapProjection.projectCryptoShelf(size, 0, 2);
      final b = FinanceMapProjection.projectCryptoShelf(size, 1, 2);
      final hub = FinanceMapProjection.projectPoint(
        size,
        FinanceMapProjection.cryptoHubCenter,
      );
      expect(a.dx, closeTo(hub.dx, 0.0001));
      expect(b.dx, closeTo(hub.dx, 0.0001));
      expect(a.dy, lessThan(hub.dy));
      expect(b.dy, greaterThan(hub.dy));
      expect(a.dy, inInclusiveRange(0.0, size.height));
      expect(b.dy, inInclusiveRange(0.0, size.height));
    });
  });
}
