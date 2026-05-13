import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'horizontal_swipe_action.dart';

class HorizontalGestureGuardNotification extends Notification {
  const HorizontalGestureGuardNotification({
    required this.pointer,
    required this.active,
    this.consumeAncestors = false,
  });

  final int pointer;
  final bool active;
  final bool consumeAncestors;
}

class HorizontalGestureGuard extends StatefulWidget {
  const HorizontalGestureGuard({
    super.key,
    required this.child,
    this.onSwipe,
    this.swipeThreshold = 48,
    this.behavior = HitTestBehavior.translucent,
    this.claimHorizontalDrag = false,
    this.axisLockThreshold = 18,
    this.horizontalDominanceRatio = 1.2,
  });

  final Widget child;
  final ValueChanged<HorizontalSwipeDirection>? onSwipe;
  final double swipeThreshold;
  final HitTestBehavior behavior;
  final bool claimHorizontalDrag;
  final double axisLockThreshold;
  final double horizontalDominanceRatio;

  @override
  State<HorizontalGestureGuard> createState() => _HorizontalGestureGuardState();
}

class _HorizontalGestureGuardState extends State<HorizontalGestureGuard> {
  final Map<int, Offset> _startPositions = <int, Offset>{};
  final Set<int> _activePointers = <int>{};

  void _setActive(int pointer, bool active) {
    final changed = active
        ? _activePointers.add(pointer)
        : _activePointers.remove(pointer);
    if (!changed) return;
    HorizontalGestureGuardNotification(
      pointer: pointer,
      active: active,
      consumeAncestors: widget.claimHorizontalDrag,
    ).dispatch(context);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startPositions[event.pointer] = event.position;
    _setActive(event.pointer, true);
  }

  void _handlePointerMove(PointerMoveEvent event) {}

  void _handlePointerUp(PointerUpEvent event) {
    final start = _startPositions.remove(event.pointer);
    if (start != null &&
        _activePointers.contains(event.pointer) &&
        widget.onSwipe != null) {
      final delta = event.position - start;
      if (delta.dx.abs() >= widget.swipeThreshold) {
        widget.onSwipe!(
          delta.dx > 0
              ? HorizontalSwipeDirection.backward
              : HorizontalSwipeDirection.forward,
        );
      }
    }
    _setActive(event.pointer, false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _startPositions.remove(event.pointer);
    _setActive(event.pointer, false);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Listener(
      behavior: widget.behavior,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.child,
    );

    if (widget.claimHorizontalDrag) {
      child = RawGestureDetector(
        behavior: widget.behavior,
        gestures: {
          _GuardHorizontalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                  _GuardHorizontalDragGestureRecognizer>(
            () => _GuardHorizontalDragGestureRecognizer(),
            (instance) {},
          ),
        },
        child: child,
      );
    }

    return child;
  }
}

class _GuardHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
