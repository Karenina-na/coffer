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
import '../core/ui/top_search_action.dart';
import '../features/account/presentation/account_create_page.dart';
import '../features/account/presentation/account_detail_page.dart';
import '../features/account/presentation/account_providers.dart';
import '../features/asset/presentation/asset_create_page.dart';
import '../features/asset/presentation/asset_detail_page.dart';
import '../features/asset/presentation/asset_providers.dart';
import '../features/backup/presentation/backup_page.dart';
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

GoRouter buildRouter() => GoRouter(
      initialLocation: '/dashboard',
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

class _HomeShell extends ConsumerWidget {
  const _HomeShell({required this.location, required this.child});

  static const _navHorizontalMargin = 16.0;
  static const _navBottomGap = 12.0;

  final String location;
  final Widget child;

  static const _tabs = [
    ('/dashboard', Icons.dashboard_outlined, '仪表盘'),
    ('/holdings', Icons.account_balance_wallet_outlined, '资金'),
    ('/events', Icons.event_note_outlined, '事件'),
    ('/rates', Icons.currency_exchange_outlined, '汇率'),
    ('/cards', Icons.credit_card_outlined, '卡片'),
  ];

  int get _index {
    final i = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadEventCountProvider);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _openGlobalSearchForCurrent(context, ref),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _openGlobalSearchForCurrent(context, ref),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                left: _navHorizontalMargin,
                right: _navHorizontalMargin,
                bottom: bottomSafeArea + _navBottomGap,
                child: _FloatingNavBar(
                  selectedIndex: _index,
                  tabs: _tabs,
                  unreadBadge: unread > 0,
                  onTap: (i) => context.go(_tabs[i].$1),
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
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.unreadBadge,
    required this.onTap,
  });

  final int selectedIndex;
  final List<(String, IconData, String)> tabs;
  final bool unreadBadge;
  final ValueChanged<int> onTap;

  static const _pillRadius = 24.0;
  static const _barHeight = 64.0;
  static const _itemRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final itemWidth = (MediaQuery.sizeOf(context).width - 32 - 8) / 5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_pillRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: _barHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: GwpColors.surface1.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(_pillRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
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
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.03),
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
                        Colors.white.withValues(alpha: 0.035),
                        Colors.white.withValues(alpha: 0.01),
                        Colors.white.withValues(alpha: 0.035),
                      ],
                    ),
                  ),
                ),
              ),
              // Active indicator — slides between items
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: selectedIndex * itemWidth + 4,
                top: 8,
                child: Container(
                  width: itemWidth - 8,
                  height: _barHeight - 16,
                  decoration: BoxDecoration(
                    color: GwpColors.actionPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(_itemRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
              // Tab items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      SizedBox(
                        width: itemWidth,
                        child: _NavItem(
                          icon: tabs[i].$2,
                          label: tabs[i].$3,
                          isSelected: i == selectedIndex,
                          showBadge: unreadBadge && tabs[i].$1 == '/events',
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
