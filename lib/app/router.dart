import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors.dart';
import '../core/result.dart';
import '../core/ui/design_tokens.dart';
import '../core/ui/global_search_delegate.dart';
import '../core/ui/gwp_empty_state.dart';
import '../core/ui/horizontal_swipe_action.dart';
import '../core/ui/top_search_action.dart';
import '../features/account/presentation/account_create_page.dart';
import '../features/account/presentation/account_detail_page.dart';
import '../features/account/presentation/account_providers.dart';
import '../features/asset/presentation/asset_create_page.dart';
import '../features/asset/presentation/asset_detail_page.dart';
import '../features/asset/presentation/asset_providers.dart';
import '../features/backup/presentation/backup_export_page.dart';
import '../features/backup/presentation/backup_page.dart';
import '../features/backup/presentation/backup_restore_page.dart';
import '../features/card/presentation/card_create_page.dart';
import '../features/card/presentation/card_list_page.dart';
import '../features/card/presentation/card_providers.dart';
import '../features/channel/presentation/channel_create_page.dart';
import '../features/channel/presentation/channel_detail_page.dart';
import '../features/channel/presentation/channel_list_page.dart';
import '../features/channel/presentation/channel_providers.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/event/presentation/event_create_page.dart';
import '../features/event/presentation/event_list_page.dart';
import '../features/event/presentation/event_providers.dart';
import '../features/exchange_rate/presentation/exchange_rate_list_page.dart';
import '../features/holdings/presentation/holdings_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/topology/presentation/topology_page.dart';

GoRouter buildRouter({String initialLocation = '/dashboard'}) => GoRouter(
      initialLocation: initialLocation,
      // 非法深链接或路由匹配失败时给空态页，避免白屏/崩溃。
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(),
        body: GwpEmptyState.error(
          message: '页面不存在: ${state.matchedLocation}',
          onRetry: () => context.go('/dashboard'),
        ),
      ),
      routes: [
        ShellRoute(
          builder: (context, state, child) => _HomeShell(
            location: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardPage(),
            ),
            GoRoute(
              path: '/holdings',
              builder: (_, state) {
                final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
                return HoldingsPage(initialTab: tab);
              },
            ),
            GoRoute(
              path: '/cards',
              builder: (_, _) => const CardListPage(),
            ),
            GoRoute(
              path: '/rates',
              builder: (_, _) => const ExchangeRateListPage(),
            ),
            GoRoute(
              path: '/events',
              builder: (_, _) => const EventListPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/accounts/new',
          builder: (_, _) => const AccountCreatePage(),
        ),
        GoRoute(
          path: '/accounts/:id/edit',
          builder: (_, state) => _EntityEditLoader(
            load: (ref) => ref
                .read(accountRepositoryProvider)
                .findById(state.pathParameters['id']!),
            pageBuilder: (entity) => AccountCreatePage(initial: entity),
          ),
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (_, state) =>
              AccountDetailPage(accountId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assets/new',
          builder: (_, _) => const AssetCreatePage(),
        ),
        GoRoute(
          path: '/assets/:id/edit',
          builder: (_, state) => _EntityEditLoader(
            load: (ref) => ref
                .read(assetRepositoryProvider)
                .findById(state.pathParameters['id']!),
            pageBuilder: (entity) => AssetCreatePage(initial: entity),
          ),
        ),
        GoRoute(
          path: '/assets/:id',
          builder: (_, state) =>
              AssetDetailPage(assetId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cards/new',
          builder: (_, _) => const CardCreatePage(),
        ),
        GoRoute(
          path: '/cards/:id/edit',
          builder: (_, state) => _EntityEditLoader(
            load: (ref) => ref
                .read(cardRepositoryProvider)
                .findById(state.pathParameters['id']!),
            pageBuilder: (entity) => CardCreatePage(initial: entity),
          ),
        ),
        GoRoute(
          path: '/channels',
          builder: (_, _) => const ChannelListPage(),
        ),
        GoRoute(
          path: '/channels/new',
          builder: (_, _) => const ChannelCreatePage(),
        ),
        GoRoute(
          path: '/channels/:id/edit',
          builder: (_, state) => _EntityEditLoader(
            load: (ref) => ref
                .read(channelRepositoryProvider)
                .findById(state.pathParameters['id']!),
            pageBuilder: (entity) => ChannelCreatePage(initial: entity),
          ),
        ),
        GoRoute(
          path: '/channels/:id',
          builder: (_, state) =>
              ChannelDetailPage(channelId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/topology',
          builder: (_, _) => const TopologyPage(),
        ),
        GoRoute(
          path: '/backup',
          builder: (_, _) => const BackupPage(),
        ),
        GoRoute(
          path: '/backup/export',
          builder: (_, _) => const BackupExportPage(),
        ),
        GoRoute(
          path: '/backup/restore',
          builder: (_, _) => const BackupRestorePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsPage(),
        ),
        GoRoute(
          path: '/events/new',
          builder: (_, state) {
            final d = state.uri.queryParameters['day'];
            DateTime? initial;
            if (d != null) {
              try {
                initial = DateTime.parse(d);
              } catch (_) {}
            }
            return EventCreatePage(initialDay: initial);
          },
        ),
      ],
    );

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  late final MainNavigationSwipeAction _mainNavigationSwipeAction;
  static const _navHorizontalMargin = 16.0;
  static const _navBottomGap = 12.0;
  static const _navTransitionFallback = Duration(milliseconds: 350);

  static const _tabs = [
    ('/dashboard', Icons.dashboard_outlined, '仪表盘'),
    ('/holdings', Icons.account_balance_wallet_outlined, '资金'),
    ('/events', Icons.event_note_outlined, '事件'),
    ('/rates', Icons.currency_exchange_outlined, '汇率'),
    ('/cards', Icons.credit_card_outlined, '卡片'),
  ];

  int? _pendingTabIndex;
  Timer? _navTransitionTimer;

  @override
  void initState() {
    super.initState();
    _mainNavigationSwipeAction = ref.read(mainNavigationSwipeActionProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mainNavigationSwipeAction.set((direction) async {
        _switchMainTab(context, direction);
        return true;
      });
    });
  }

  @override
  void dispose() {
    _navTransitionTimer?.cancel();
    _mainNavigationSwipeAction.clearLater();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location == widget.location) return;
    _unlockPendingTabIfSettled();
  }

  int get _index {
    final i = _tabs.indexWhere((t) => widget.location.startsWith(t.$1));
    return i < 0 ? 0 : i;
  }

  bool get _isMainTabTransitionPending => _pendingTabIndex != null;

  String _routeForIndex(int index) => _tabs[index].$1;

  bool _matchesMainTabRoute(String location, int index) {
    return location.startsWith(_routeForIndex(index));
  }

  void _unlockPendingTabIfSettled() {
    final pending = _pendingTabIndex;
    if (pending == null) return;
    if (!_matchesMainTabRoute(widget.location, pending)) return;
    _navTransitionTimer?.cancel();
    _navTransitionTimer = null;
    _pendingTabIndex = null;
  }

  bool _requestMainTabChange(
    BuildContext context,
    int targetIndex,
  ) {
    if (targetIndex < 0 || targetIndex >= _tabs.length) return false;
    if (targetIndex == _index) return false;
    if (_pendingTabIndex == targetIndex) return false;
    if (_isMainTabTransitionPending) return false;
    _pendingTabIndex = targetIndex;
    _navTransitionTimer?.cancel();
    _navTransitionTimer = Timer(_navTransitionFallback, () {
      if (!mounted) return;
      _pendingTabIndex = null;
      _navTransitionTimer = null;
    });
    context.go(_routeForIndex(targetIndex));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final unread = ref.watch(unreadEventCountProvider);
    final horizontalSwipeHandler = ref.watch(horizontalSwipeActionProvider);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showNav = keyboardInset == 0;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _openGlobalSearchForCurrent(context, ref),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _openGlobalSearchForCurrent(context, ref),
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => KeyEventResult.ignored,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (showNav)
                  Positioned(
                    left: _navHorizontalMargin,
                    right: _navHorizontalMargin,
                    bottom: bottomSafeArea + _navBottomGap,
                    child: _FloatingNavBar(
                      selectedIndex: _index,
                      tabs: _tabs,
                      unreadBadge: unread > 0,
                      onHorizontalSwipe: (direction) async {
                        if (!context.mounted) return;
                        final handled =
                            await horizontalSwipeHandler?.call(direction) ?? false;
                        if (!context.mounted) return;
                        if (handled) return;
                        _switchMainTab(context, direction);
                      },
                      onTap: (i) => _requestMainTabChange(context, i),
                    ),
                  ),
              ],
            ),
          ),
      ),
    );
  }

  void _openGlobalSearchForCurrent(BuildContext context, WidgetRef ref) {
    // 若当前 Tab 已注册搜索入口，优先复用（会带该 Tab 的 override）。
    final opener = ref.read(topSearchOpenerProvider);
    if (opener != null) {
      opener();
      return;
    }
    // 否则走默认（按路由推断当前 feature）。
    final f = switch (_index) {
      1 => SearchFeature.accounts, // /holdings 默认把账户视作当前模块
      2 => SearchFeature.events,
      3 => SearchFeature.rates,
      4 => SearchFeature.cards,
      _ => SearchFeature.dashboard,
    };
    openGlobalSearch(context: context, ref: ref, current: f);
  }

  void _switchMainTab(
    BuildContext context,
    HorizontalSwipeDirection direction,
  ) {
    final nextIndex = switch (direction) {
      HorizontalSwipeDirection.backward => _index - 1,
      HorizontalSwipeDirection.forward => _index + 1,
    };
    _requestMainTabChange(context, nextIndex);
  }
}

class _FloatingNavBar extends StatefulWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.unreadBadge,
    required this.onTap,
    required this.onHorizontalSwipe,
  });

  final int selectedIndex;
  final List<(String, IconData, String)> tabs;
  final bool unreadBadge;
  final ValueChanged<int> onTap;
  final Future<void> Function(HorizontalSwipeDirection direction)
      onHorizontalSwipe;

  static const _pillRadius = 24.0;
  static const _barHeight = 64.0;
  static const _itemRadius = 20.0;
  static const _innerHorizontalInset = 4.0;
  static const _indicatorVerticalInset = 8.0;
  static const _swipeDistanceThreshold = 24.0;

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar> {
  double? _dragStartX;
  bool _swipeTriggered = false;

  double _alignmentXForIndex(int index, int count) {
    if (count <= 1) return 0;
    return -1 + (2 * index / (count - 1));
  }

  void _resetDrag() {
    _dragStartX = null;
    _swipeTriggered = false;
  }

  void _handleDragMove(DragUpdateDetails details) {
    final startX = _dragStartX;
    if (startX == null || _swipeTriggered) return;
    final delta = details.globalPosition.dx - startX;
    if (delta.abs() < _FloatingNavBar._swipeDistanceThreshold) return;
    _swipeTriggered = true;
    final direction = delta > 0
        ? HorizontalSwipeDirection.backward
        : HorizontalSwipeDirection.forward;
    unawaited(widget.onHorizontalSwipe(direction));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _dragStartX = event.position.dx;
        _swipeTriggered = false;
      },
      onPointerUp: (_) => _resetDrag(),
      onPointerCancel: (_) => _resetDrag(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _handleDragMove,
        onHorizontalDragEnd: (_) => _resetDrag(),
        onHorizontalDragCancel: _resetDrag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_FloatingNavBar._pillRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: _FloatingNavBar._barHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: GwpColors.surface1.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(_FloatingNavBar._pillRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.07),
                            Colors.white.withValues(alpha: 0.015),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.02),
                            Colors.white.withValues(alpha: 0.006),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _FloatingNavBar._innerHorizontalInset,
                      vertical: _FloatingNavBar._indicatorVerticalInset,
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                        _alignmentXForIndex(widget.selectedIndex, widget.tabs.length),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / widget.tabs.length,
                        heightFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: GwpColors.actionPrimary.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(
                                _FloatingNavBar._itemRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.045),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _FloatingNavBar._innerHorizontalInset,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.tabs.length; i++)
                          Expanded(
                            child: _NavItem(
                              icon: widget.tabs[i].$2,
                              label: widget.tabs[i].$3,
                              isSelected: i == widget.selectedIndex,
                              showBadge: widget.unreadBadge &&
                                  widget.tabs[i].$1 == '/events',
                              onTap: () => widget.onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_FloatingNavBar._itemRadius),
        splashFactory: InkRipple.splashFactory,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? GwpColors.textSecondary : GwpColors.textMuted,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              showBadge
                  ? Badge(
                      backgroundColor: GwpColors.negative,
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? GwpColors.actionPrimaryHover
                            : GwpColors.textMuted,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? GwpColors.actionPrimaryHover
                          : GwpColors.textMuted,
                    ),
              const SizedBox(height: 4),
              Text(label, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 加载单一实体后切到编辑页的通用桥接 widget。
///
/// - [load] 在 provider 上下文里取得实体（使用 `ref.read` 避免重复触发）。
/// - [pageBuilder] 拿到实体后构造编辑页（通常是 *CreatePage(initial: entity)）。
class _EntityEditLoader<T> extends ConsumerStatefulWidget {
  const _EntityEditLoader({
    required this.load,
    required this.pageBuilder,
  });

  final Future<Result<T, AppError>> Function(WidgetRef ref) load;
  final Widget Function(T entity) pageBuilder;

  @override
  ConsumerState<_EntityEditLoader<T>> createState() =>
      _EntityEditLoaderState<T>();
}

class _EntityEditLoaderState<T> extends ConsumerState<_EntityEditLoader<T>> {
  late Future<Result<T, AppError>> _future = widget.load(ref);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<T, AppError>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data!;
        return result.when(
          ok: widget.pageBuilder,
          err: (e) => Scaffold(
            appBar: AppBar(),
            body: GwpEmptyState.error(
              message: '加载失败: ${e.message}',
              onRetry: () => setState(() {
                _future = widget.load(ref);
              }),
            ),
          ),
        );
      },
    );
  }
}
