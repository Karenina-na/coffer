import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/ui/projected_label_layout.dart';

void main() {
  group('computeProjectedLabelPlacements', () {
    test('higher-priority labels take the first available slot before lower-priority labels', () {
      final placements = computeProjectedLabelPlacements(
        const Size(160, 120),
        const [
          ProjectedLabelSpec(
            id: 'high',
            center: Offset(80, 60),
            size: Size(28, 10),
            priority: 100,
          ),
          ProjectedLabelSpec(
            id: 'low',
            center: Offset(80, 60),
            size: Size(28, 10),
            priority: 10,
          ),
        ],
      );

      final high = placements.firstWhere((p) => p.id == 'high');
      final low = placements.firstWhere((p) => p.id == 'low');
      expect(high.visible, isTrue);
      expect(low.visible, isTrue);
      expect(high.slot, ProjectedLabelSlot.ne);
      expect(low.slot, isNot(ProjectedLabelSlot.ne));
      expect(high.rect.overlaps(low.rect), isFalse);
    });

    test('keepVisible labels still receive placement when the canvas is saturated', () {
      final placements = computeProjectedLabelPlacements(
        const Size(80, 60),
        const [
          ProjectedLabelSpec(
            id: 'selected',
            center: Offset(40, 30),
            size: Size(28, 10),
            keepVisible: true,
            maxRing: 2,
          ),
          ProjectedLabelSpec(
            id: 'other',
            center: Offset(40, 30),
            size: Size(28, 10),
            priority: 1,
            maxRing: 2,
          ),
        ],
        reservedRects: const [Rect.fromLTWH(0, 0, 80, 60)],
      );

      final selected = placements.firstWhere((p) => p.id == 'selected');
      final other = placements.firstWhere((p) => p.id == 'other');
      expect(selected.visible, isTrue);
      expect(other.visible, isFalse);
    });

    test('displaced labels report leader lines only after exceeding threshold', () {
      final placements = computeProjectedLabelPlacements(
        const Size(180, 120),
        const [
          ProjectedLabelSpec(
            id: 'anchor',
            center: Offset(20, 20),
            size: Size(34, 12),
            keepVisible: true,
            gap: 10,
            maxRing: 1,
            leaderThreshold: 8,
            preferredSlots: [ProjectedLabelSlot.se],
          ),
        ],
      );

      final placement = placements.single;
      expect(placement.visible, isTrue);
      expect(placement.showLeaderLine, isTrue);
    });
  });
}
