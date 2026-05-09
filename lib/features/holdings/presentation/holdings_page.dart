import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../../core/ui/global_search_delegate.dart';
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
  bool _boundaryHandoffLocked = false;
  bool _syncingTabToRoute = false;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialTab ?? 0).clamp(0, 3);
    _horizontalSwipeAction = ref.read(horizontalSwipeActionProvider.notifier);
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    _tab = TabController(length: 4, vsync: this, initialIndex: initial)
      ..addListener(() {
        if (!mounted) return;
        setState(() {}); // rebuild AppBar/FAB per active tab
        _syncTopSearch(); // 转账 tab 走全局搜索，其它 tab 各自模块优先
        if (!_tab.indexIsChanging) {
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

  bool _handleBoundaryScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      _boundaryHandoffLocked = false;
      return false;
    }
    if (notification is ScrollEndNotification) {
      _boundaryHandoffLocked = false;
      return false;
    }
    if (notification is! OverscrollNotification || _boundaryHandoffLocked) {
      return false;
    }

    final direction = switch (notification.overscroll.sign) {
      < 0 => HorizontalSwipeDirection.backward,
      > 0 => HorizontalSwipeDirection.forward,
      _ => null,
    };
    if (direction == null) return false;

    final isAtLeadingEdge = _tab.index == 0 &&
        direction == HorizontalSwipeDirection.backward;
    final isAtTrailingEdge = _tab.index == _tab.length - 1 &&
        direction == HorizontalSwipeDirection.forward;
    if (!isAtLeadingEdge && !isAtTrailingEdge) return false;

    final binding = ref.read(mainNavigationSwipeActionProvider);
    final handler = binding?.handler;
    if (handler == null) return false;
    _boundaryHandoffLocked = true;
    Future<void>.microtask(() async {
      final handled = await handler(direction);
      if (!mounted || handled) return;
      _boundaryHandoffLocked = false;
    });
    return false;
  }

  void _syncTopSearch() {
    final idx = _tab.index;
    ref
        .read(topSearchOpenerProvider.notifier)
        .set(this, () => _openSearch(context, idx));
  }

  @override
  Widget build(BuildContext context) {
    final idx = _tab.index;
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
      floatingActionButton: _shellFabFor(context, idx),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleBoundaryScroll,
        child: TabBarView(
          controller: _tab,
          children: const [
            AccountListBody(),
            AssetListBody(),
            TransferSimulateBody(),
            PortfolioAnalysisBody(),
          ],
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

  Widget? _fabFor(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => context.push('/accounts/new'),
          icon: const Icon(Icons.add),
          label: const Text('新建账户'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => context.push('/assets/new'),
          icon: const Icon(Icons.add),
          label: const Text('新建资产'),
        );
      default:
        return null; // transfer tab: 无 FAB（页面内有 "模拟报价" 按钮）
    }
  }

  Widget? _shellFabFor(BuildContext context, int idx) {
    final fab = _fabFor(context, idx);
    if (fab == null) return null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: FloatingNavLayout.totalFloatingHeight(context) + GwpSpacing.md,
      ),
      child: fab,
    );
  }
}
