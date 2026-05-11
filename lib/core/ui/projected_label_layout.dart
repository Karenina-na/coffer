import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ProjectedLabelSlot { ne, e, se, nw, w, sw, n, s }

class ProjectedLabelSpec {
  const ProjectedLabelSpec({
    required this.id,
    required this.center,
    required this.size,
    this.anchorRadius = 0,
    this.priority = 0,
    this.keepVisible = false,
    this.gap = 4,
    this.maxRing = 2,
    this.ringSpacing = 12,
    this.leaderThreshold = 14,
    this.preferredSlots = const [
      ProjectedLabelSlot.ne,
      ProjectedLabelSlot.e,
      ProjectedLabelSlot.se,
      ProjectedLabelSlot.nw,
      ProjectedLabelSlot.w,
      ProjectedLabelSlot.sw,
      ProjectedLabelSlot.n,
      ProjectedLabelSlot.s,
    ],
  });

  final String id;
  final Offset center;
  final Size size;
  final double anchorRadius;
  final int priority;
  final bool keepVisible;
  final double gap;
  final int maxRing;
  final double ringSpacing;
  final double leaderThreshold;
  final List<ProjectedLabelSlot> preferredSlots;
}

class ProjectedLabelPlacement {
  const ProjectedLabelPlacement({
    required this.id,
    required this.rect,
    required this.attachPoint,
    required this.visible,
    required this.showLeaderLine,
    required this.slot,
  });

  final String id;
  final Rect rect;
  final Offset attachPoint;
  final bool visible;
  final bool showLeaderLine;
  final ProjectedLabelSlot slot;
}

List<ProjectedLabelPlacement> computeProjectedLabelPlacements(
  Size canvasSize,
  List<ProjectedLabelSpec> specs, {
  List<Rect> reservedRects = const [],
  double padding = 2,
}) {
  final ordered = [...specs]..sort((a, b) {
    if (a.keepVisible != b.keepVisible) {
      return a.keepVisible ? -1 : 1;
    }
    return b.priority.compareTo(a.priority);
  });

  final occupied = reservedRects.map((rect) => rect.inflate(1)).toList();
  final placements = <String, ProjectedLabelPlacement>{};

  for (final spec in ordered) {
    final candidates = _buildCandidates(spec);
    _Candidate? chosen;

    for (final candidate in candidates) {
      if (!_isInside(candidate.rect, canvasSize, padding)) continue;
      if (_overlapsAny(candidate.rect, occupied)) continue;
      chosen = candidate;
      break;
    }

    chosen ??= spec.keepVisible
        ? _pickLeastOverlapCandidate(candidates, occupied, canvasSize, padding)
        : null;

    if (chosen == null) {
      placements[spec.id] = ProjectedLabelPlacement(
        id: spec.id,
        rect: Rect.zero,
        attachPoint: spec.center,
        visible: false,
        showLeaderLine: false,
        slot: spec.preferredSlots.first,
      );
      continue;
    }

    final attachPoint = _closestPointOnRect(spec.center, chosen.rect);
    final showLeaderLine =
        (attachPoint - spec.center).distance > spec.anchorRadius + spec.leaderThreshold;

    final placement = ProjectedLabelPlacement(
      id: spec.id,
      rect: chosen.rect,
      attachPoint: attachPoint,
      visible: true,
      showLeaderLine: showLeaderLine,
      slot: chosen.slot,
    );
    placements[spec.id] = placement;
    occupied.add(chosen.rect.inflate(1));
  }

  return specs
      .map((spec) => placements[spec.id]!)
      .toList(growable: false);
}

class _Candidate {
  const _Candidate({required this.rect, required this.slot});

  final Rect rect;
  final ProjectedLabelSlot slot;
}

List<_Candidate> _buildCandidates(ProjectedLabelSpec spec) {
  final candidates = <_Candidate>[];
  for (var ring = 0; ring < spec.maxRing; ring++) {
    final distance = spec.anchorRadius + spec.gap + ring * spec.ringSpacing;
    for (final slot in spec.preferredSlots) {
      final anchor = _slotAnchor(spec.center, slot, distance);
      candidates.add(_Candidate(
        rect: _rectForSlot(anchor, spec.size, slot),
        slot: slot,
      ));
    }
  }
  return candidates;
}

Offset _slotAnchor(Offset center, ProjectedLabelSlot slot, double distance) {
  switch (slot) {
    case ProjectedLabelSlot.ne:
      return Offset(center.dx + distance, center.dy - distance);
    case ProjectedLabelSlot.e:
      return Offset(center.dx + distance, center.dy);
    case ProjectedLabelSlot.se:
      return Offset(center.dx + distance, center.dy + distance);
    case ProjectedLabelSlot.nw:
      return Offset(center.dx - distance, center.dy - distance);
    case ProjectedLabelSlot.w:
      return Offset(center.dx - distance, center.dy);
    case ProjectedLabelSlot.sw:
      return Offset(center.dx - distance, center.dy + distance);
    case ProjectedLabelSlot.n:
      return Offset(center.dx, center.dy - distance);
    case ProjectedLabelSlot.s:
      return Offset(center.dx, center.dy + distance);
  }
}

Rect _rectForSlot(Offset anchor, Size size, ProjectedLabelSlot slot) {
  switch (slot) {
    case ProjectedLabelSlot.ne:
      return Rect.fromLTWH(anchor.dx, anchor.dy - size.height, size.width, size.height);
    case ProjectedLabelSlot.e:
      return Rect.fromLTWH(anchor.dx, anchor.dy - size.height / 2, size.width, size.height);
    case ProjectedLabelSlot.se:
      return Rect.fromLTWH(anchor.dx, anchor.dy, size.width, size.height);
    case ProjectedLabelSlot.nw:
      return Rect.fromLTWH(
        anchor.dx - size.width,
        anchor.dy - size.height,
        size.width,
        size.height,
      );
    case ProjectedLabelSlot.w:
      return Rect.fromLTWH(
        anchor.dx - size.width,
        anchor.dy - size.height / 2,
        size.width,
        size.height,
      );
    case ProjectedLabelSlot.sw:
      return Rect.fromLTWH(anchor.dx - size.width, anchor.dy, size.width, size.height);
    case ProjectedLabelSlot.n:
      return Rect.fromLTWH(
        anchor.dx - size.width / 2,
        anchor.dy - size.height,
        size.width,
        size.height,
      );
    case ProjectedLabelSlot.s:
      return Rect.fromLTWH(anchor.dx - size.width / 2, anchor.dy, size.width, size.height);
  }
}

bool _isInside(Rect rect, Size canvasSize, double padding) {
  return rect.left >= padding &&
      rect.top >= padding &&
      rect.right <= canvasSize.width - padding &&
      rect.bottom <= canvasSize.height - padding;
}

bool _overlapsAny(Rect rect, List<Rect> occupied) {
  for (final other in occupied) {
    if (rect.overlaps(other)) return true;
  }
  return false;
}

_Candidate _pickLeastOverlapCandidate(
  List<_Candidate> candidates,
  List<Rect> occupied,
  Size canvasSize,
  double padding,
) {
  _Candidate? best;
  var bestScore = double.infinity;

  for (final candidate in candidates) {
    final bounded = Rect.fromLTWH(
      candidate.rect.left.clamp(padding, math.max(padding, canvasSize.width - padding - candidate.rect.width)).toDouble(),
      candidate.rect.top.clamp(padding, math.max(padding, canvasSize.height - padding - candidate.rect.height)).toDouble(),
      candidate.rect.width,
      candidate.rect.height,
    );

    var score = 0.0;
    for (final other in occupied) {
      final overlap = bounded.intersect(other);
      if (!overlap.isEmpty) score += overlap.width * overlap.height;
    }

    if (score < bestScore) {
      bestScore = score;
      best = _Candidate(rect: bounded, slot: candidate.slot);
    }
  }

  return best ?? candidates.first;
}

Offset _closestPointOnRect(Offset point, Rect rect) {
  return Offset(
    point.dx.clamp(rect.left, rect.right).toDouble(),
    point.dy.clamp(rect.top, rect.bottom).toDouble(),
  );
}
