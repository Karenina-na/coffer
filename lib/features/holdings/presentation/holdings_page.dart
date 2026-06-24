import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_top_bar.dart';
import '../../search/presentation/global_search_delegate.dart';
import '../../../core/ui/horizontal_gesture_guard.dart';
import '../../../core/ui/horizontal_swipe_action.dart';
import '../../../core/ui/top_search_action.dart';
import '../../account/presentation/account_list_page.dart';
import '../../asset/presentation/asset_list_page.dart';
import '../../channel/presentation/transfer_simulate_page.dart';
import 'portfolio_analysis_body.dart';

/// Merged main page grouping tightly-coupled entities:
/// 账户 (Account) ← 资产 (Asset) 绑定账户 / 转账 (Transfer) 在账户之间移动资金。
class HoldingsPage extends ConsumerStatefulWidget {
  const HoldingsPage({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends ConsumerState<HoldingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final HorizontalSwipeAction _horizontalSwipeAction;
  late final TopSearchOpener _topSearchOpener;
  bool _syncingTabToRoute = false;
  final Set<int> _guardedPointers = <int>{};
  final Set<int> _blockedPointers = <int>{};
  Offset? _dragStartPosition;
  bool _swipeTriggered = false;
  bool _verticalLocked = false;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialTab ?? 0).clamp(0, 3);
    _horizontalSwipeAction = ref.read(horizontalSwipeActionProvider.notifier);
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    _tab = TabController(length: 4, vsync: this, initialIndex: initial)
      ..addListener(() {
        if (!mounted) return;
        setState(() {});
        if (!_tab.indexIsChanging) {
          _syncTopSearch();
          unawaited(_syncRouteTab());
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTopSearch();
      _horizontalSwipeAction.set(this, _handleHorizontalSwipe);
    });
  }

  @override
  void didUpdateWidget(covariant HoldingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = (widget.initialTab ?? 0).clamp(0, 3);
    if (_tab.index == target || _syncingTabToRoute) return;
    scheduleMicrotask(() {
      if (!mounted || _tab.index == target) return;
      _tab.animateTo(target);
    });
  }

  @override
  void dispose() {
    _topSearchOpener.clearLater(this);
    _horizontalSwipeAction.clearLater(this);
    _tab.dispose();
    super.dispose();
  }

  Future<bool> _handleHorizontalSwipe(
    HorizontalSwipeDirection direction,
  ) async {
    final nextIndex = switch (direction) {
      HorizontalSwipeDirection.backward => _tab.index - 1,
      HorizontalSwipeDirection.forward => _tab.index + 1,
    };
    if (nextIndex < 0 || nextIndex >= _tab.length) return false;
    _tab.animateTo(nextIndex);
    return true;
  }

  Future<void> _syncRouteTab() async {
    if (!mounted) return;
    final route = GoRouterState.of(context).uri;
    final currentTab = int.tryParse(route.queryParameters['tab'] ?? '') ?? 0;
    if (currentTab == _tab.index) return;
    final nextQuery = Map<String, String>.from(route.queryParameters)
      ..['tab'] = '${_tab.index}';
    final nextUri = route.replace(queryParameters: nextQuery);
    _syncingTabToRoute = true;
    context.go(nextUri.toString());
    await Future<void>.microtask(() {});
    _syncingTabToRoute = false;
  }

  bool _handleGuardNotification(
    HorizontalGestureGuardNotification notification,
  ) {
    if (notification.active) {
      _guardedPointers.add(notification.pointer);
      _blockedPointers.add(notification.pointer);
    } else {
      _guardedPointers.remove(notification.pointer);
    }
    return notification.consumeAncestors;
  }

  bool _handleBoundaryScroll(ScrollNotification notification) {
    return false;
  }

  void _resetDrag() {
    _dragStartPosition = null;
    _swipeTriggered = false;
    _verticalLocked = false;
  }

  Future<void> _handleTabSwipe(HorizontalSwipeDirection direction) async {
    if (_guardedPointers.isNotEmpty || _swipeTriggered) return;
    _swipeTriggered = true;
    final handled = await _handleHorizontalSwipe(direction);
    if (handled) return;
    final binding = ref.read(mainNavigationSwipeActionProvider);
    final handler = binding?.handler;
    if (handler == null) return;
    await handler(direction);
  }

  void _syncTopSearch() {
    final idx = _tab.index;
    ref
        .read(topSearchOpenerProvider.notifier)
        .set(this, () => _openSearch(context, idx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('资金'),
        showAppIcon: true,
        actions: const <Widget>[],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '账户'),
            Tab(text: '资产'),
            Tab(text: '转账'),
            Tab(text: '分析'),
          ],
        ),
      ),
      body: NotificationListener<HorizontalGestureGuardNotification>(
        onNotification: _handleGuardNotification,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _dragStartPosition = event.position;
            _swipeTriggered = false;
            _verticalLocked = false;
          },
          onPointerMove: (event) {
            final start = _dragStartPosition;
            if (start == null ||
                _swipeTriggered ||
                _guardedPointers.isNotEmpty ||
                _blockedPointers.contains(event.pointer)) {
              return;
            }
            final delta = event.position - start;
            final dx = delta.dx.abs();
            final dy = delta.dy.abs();
            // Once the gesture shows clear vertical intent, lock out
            // horizontal swipe for the remainder of this gesture to
            // prevent false triggers during vertical scrolling.
            if (!_verticalLocked && dy > 24 && dy > dx * 0.8) {
              _verticalLocked = true;
            }
            if (_verticalLocked) return;
            if (dx < 56) return;
            if (dx <= dy * 1.35) return;
            unawaited(
              _handleTabSwipe(
                delta.dx > 0
                    ? HorizontalSwipeDirection.backward
                    : HorizontalSwipeDirection.forward,
              ),
            );
          },
          onPointerUp: (event) {
            final start = _dragStartPosition;
            if (start != null &&
                !_swipeTriggered &&
                _guardedPointers.isEmpty &&
                !_blockedPointers.contains(event.pointer)) {
              final delta = event.position - start;
              final dx = delta.dx.abs();
              final dy = delta.dy.abs();
              if (dx >= 120 && dx > dy * 1.5) {
                unawaited(
                  _handleTabSwipe(
                    delta.dx > 0
                        ? HorizontalSwipeDirection.backward
                        : HorizontalSwipeDirection.forward,
                  ),
                );
              }
            }
            _blockedPointers.remove(event.pointer);
            _guardedPointers.remove(event.pointer);
            _resetDrag();
          },
          onPointerCancel: (event) {
            _blockedPointers.remove(event.pointer);
            _guardedPointers.remove(event.pointer);
            _resetDrag();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleBoundaryScroll,
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                RepaintBoundary(child: AccountListBody()),
                RepaintBoundary(child: AssetListBody()),
                RepaintBoundary(child: TransferSimulateBody()),
                RepaintBoundary(child: PortfolioAnalysisBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch(BuildContext context, int idx) async {
    await openGlobalSearch(
      context: context,
      ref: ref,
      current: switch (idx) {
        0 => SearchFeature.accounts,
        1 => SearchFeature.assets,
        _ => SearchFeature.dashboard, // 转账/分析 tab：无专属列表，直接全局搜索
      },
    );
  }
}
