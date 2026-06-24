import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/ui/projected_edge_geometry.dart';

void main() {
  group('projectEdgeGeometry', () {
    test('returns projected endpoints, control point, and path geometry', () {
      final geometry = projectEdgeGeometry(
        size: const Size(360, 200),
        fromCoords: (0.30, 0.32),
        toCoords: (0.72, 0.30),
        arcLiftFactor: 0.20,
        arcDepthFactor: 0.08,
        heightLiftFactor: 0.025,
        heightDepthFactor: 0.018,
      );

      expect(geometry, isNotNull);
      expect(geometry!.from.dx, lessThan(geometry.to.dx));
      expect(geometry.control.dy, lessThan((geometry.from.dy + geometry.to.dy) / 2));
      expect(geometry.depth, inInclusiveRange(0.0, 1.0));
      expect(geometry.buildPath().getBounds().width, greaterThan(0));
    });

    test('returns null when either endpoint is missing', () {
      expect(
        projectEdgeGeometry(
          size: const Size(200, 120),
          fromCoords: null,
          toCoords: (0.5, 0.5),
        ),
        isNull,
      );
    });

    test('recommended stroke width increases with channel count', () {
      final geometry = projectEdgeGeometry(
        size: const Size(360, 200),
        fromCoords: (0.25, 0.35),
        toCoords: (0.75, 0.35),
      )!;

      final one = geometry.recommendedStrokeWidth(
        count: 1,
        base: 0.75,
        countFactor: 0.32,
        depthBase: 0.84,
        depthFactor: 0.24,
        min: 0.75,
        max: 2.4,
      );
      final three = geometry.recommendedStrokeWidth(
        count: 3,
        base: 0.75,
        countFactor: 0.32,
        depthBase: 0.84,
        depthFactor: 0.24,
        min: 0.75,
        max: 2.4,
      );

      expect(three, greaterThan(one));
    });
  });
}
