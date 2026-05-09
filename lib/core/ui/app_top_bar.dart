import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/valuation/asset_valuator.dart';
import '../../features/sync/presentation/sync_providers.dart';
import '../valuation/valuation_currency_provider.dart';
import 'base_currency_switcher.dart';
import 'settings_action.dart';
import 'sync_window_menu_button.dart';
import 'top_create_action.dart';
import 'top_search_action.dart';

/// 全局统一的顶部 AppBar。
///
/// 视觉上是一条，但逻辑分三段：
/// - 左侧 `title`：当前功能页标题（随页面变化）
/// - 右侧 `actions`：页面专有动作
/// - 固定尾部：同步药丸 → 本位币切换 → 搜索 → 设置
///
/// 页面只传入自己的 `title` / `actions` / `bottom`，固定动作由本组件追加。
/// 如需隐藏某些固定动作（例如登录/引导页），用 `showFixedActions = false`。
/// 主 Tab 页传入 `showAppIcon = true`，在左侧显示应用图标。
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showFixedActions = true,
    this.showAppIcon = false,
  });

  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool showFixedActions;
  final bool showAppIcon;

  static const double toolbarHeight = 44;

  @override
  Size get preferredSize {
    final b = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + b);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;
    final tiny = width < 340;
    final wrappedTitle = DefaultTextStyle.merge(
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      maxLines: 1,
      child: title,
    );
    final effectiveLeading = leading ??
        (showAppIcon
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'assets/branding/app_icon_gold.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : null);
    final fixedActions = showFixedActions
        ? const <Widget>[
            TopSearchAction(),
            SettingsAction(),
            _TopBarOverflowAction(),
            SizedBox(width: 4),
          ]
        : const <Widget>[];

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: compact ? 8 : null,
      title: wrappedTitle,
      leading: effectiveLeading,
      automaticallyImplyLeading:
          effectiveLeading == null && automaticallyImplyLeading,
      bottom: bottom,
      actions: [
        ...actions,
        if (actions.isNotEmpty && showFixedActions && !compact && !tiny)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
            child: VerticalDivider(
              width: 1,
              indent: 14,
              endIndent: 14,
              color: cs.outlineVariant,
            ),
          ),
        ...fixedActions,
      ],
    );
  }
}

class _TopBarOverflowAction extends StatelessWidget {
  const _TopBarOverflowAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '更多',
      icon: const Icon(Icons.more_horiz),
      onPressed: () {
        showGeneralDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierLabel: '更多',
          barrierDismissible: true,
          barrierColor: Colors.black45,
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, _, _) => const _TopBarOverflowSheet(),
          transitionBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    );
  }
}

class _TopBarOverflowSheet extends ConsumerStatefulWidget {
  const _TopBarOverflowSheet();

  @override
  ConsumerState<_TopBarOverflowSheet> createState() =>
      _TopBarOverflowSheetState();
}

class _TopBarOverflowSheetState extends ConsumerState<_TopBarOverflowSheet> {
  bool _syncExpanded = false;
  bool _currencyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final panelWidth = width < 420 ? width * 0.86 : 360.0;
    final sync = ref.watch(syncStatusProvider);
    final currentCurrency = ref.watch(valuationCurrencyProvider);
    final createActions = ref.watch(currentTopBarCreateActionsProvider);

    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 12,
          child: SizedBox(
            width: panelWidth,
            height: double.infinity,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + media.viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '更多操作',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (createActions.isNotEmpty) ...[
                      _PanelSection(
                        icon: Icons.add_circle_outline,
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: '新建',
                        expanded: true,
                        onToggle: () {},
                        collapsible: false,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final action in createActions)
                              _PanelActionChip(
                                icon: action.icon,
                                title: action.label,
                                onTap: () => _runCreateAction(context, action),
                              ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final syncSection = _PanelSection(
                          icon: _syncIcon(sync),
                          iconColor: _syncColor(context, sync),
                          title: '数据同步',
                          expanded: _syncExpanded,
                          onToggle: () {
                            setState(() => _syncExpanded = !_syncExpanded);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PanelInfoCard(
                                icon: _syncIcon(sync),
                                title: _syncTitle(sync),
                                subtitle: _syncSubtitle(sync),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _SyncRangeActionChip(
                                    icon: Icons.sync,
                                    title: '刷新全部 · 行情 + 汇率',
                                    enabled: !sync.isSyncing,
                                    maxWidth: 220,
                                    onSelected: (window) => _runSync(
                                      context,
                                      ref,
                                      scope: SyncScope.all,
                                      window: window,
                                    ),
                                  ),
                                  _SyncRangeActionChip(
                                    icon: Icons.currency_exchange,
                                    title: '仅汇率',
                                    enabled: !sync.isSyncing,
                                    onSelected: (window) => _runSync(
                                      context,
                                      ref,
                                      scope: SyncScope.ratesOnly,
                                      window: window,
                                    ),
                                  ),
                                  _SyncRangeActionChip(
                                    icon: Icons.stacked_line_chart,
                                    title: '仅资产',
                                    enabled: !sync.isSyncing,
                                    onSelected: (window) => _runSync(
                                      context,
                                      ref,
                                      scope: SyncScope.assetsOnly,
                                      window: window,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                        final currencySection = _PanelSection(
                          icon: Icons.language,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: '本位币',
                          expanded: _currencyExpanded,
                          onToggle: () {
                            setState(() => _currencyExpanded = !_currencyExpanded);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PanelInfoCard(
                                icon: Icons.currency_exchange,
                                title: '当前本位币',
                                subtitle: currentCurrency,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final code in kSupportedBaseCurrencies)
                                    _PanelChoiceChip(
                                      icon: code == currentCurrency
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      title: code,
                                      selected: code == currentCurrency,
                                      onTap: () => ref
                                          .read(valuationCurrencyProvider.notifier)
                                          .set(code),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                        final canSplit = constraints.maxWidth >= 300;
                        if (!canSplit) {
                          return Column(
                            children: [
                              syncSection,
                              const SizedBox(height: 12),
                              currencySection,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: syncSection),
                            const SizedBox(width: 12),
                            Expanded(child: currencySection),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _runSync(
    BuildContext context,
    WidgetRef ref, {
    required SyncScope scope,
    SyncMode mode = SyncMode.full,
    SyncWindow? window,
  }) {
    Navigator.of(context).pop();
    ref.read(globalRefreshProvider).run(
      scope: scope,
      rateMode: mode,
      window: window,
    );
  }

  void _runCreateAction(
    BuildContext context,
    TopBarCreateActionItem action,
  ) {
    Navigator.of(context).pop();
    context.push(action.route);
  }

  IconData _syncIcon(SyncState sync) {
    if (sync.isSyncing) return Icons.sync;
    if (sync.lastError != null) return Icons.sync_problem;
    if (sync.lastSyncAt == null) return Icons.cloud_off_outlined;
    return Icons.cloud_done_outlined;
  }

  Color _syncColor(BuildContext context, SyncState sync) {
    final cs = Theme.of(context).colorScheme;
    if (sync.isSyncing) return cs.primary;
    if (sync.lastError != null) return cs.error;
    if (sync.lastSyncAt == null) return cs.onSurfaceVariant;
    return cs.primary;
  }

  String _syncTitle(SyncState sync) {
    if (sync.isSyncing) return '正在同步';
    if (sync.lastError != null) return '同步失败';
    if (sync.lastSyncAt == null) return '尚未同步';
    return '同步状态正常';
  }

  String _syncSubtitle(SyncState sync) {
    if (sync.isSyncing) return '正在拉取行情与汇率';
    if (sync.lastError != null) return sync.lastError!;
    if (sync.lastSyncAt == null) return '点击下方操作拉取最新数据';
    return '上次同步：${_formatRelative(sync.lastSyncAt!)}';
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 30) return '刚刚';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.collapsible = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (collapsible)
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: iconColor,
                    ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelInfoCard extends StatelessWidget {
  const _PanelInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelActionChip extends StatelessWidget {
  const _PanelActionChip({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _OverflowActionChip(
      icon: icon,
      title: title,
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, size: 16, color: cs.outline),
    );
  }
}

class _SyncRangeActionChip extends StatelessWidget {
  const _SyncRangeActionChip({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onSelected,
    this.maxWidth,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final ValueChanged<SyncWindow> onSelected;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SyncWindowMenuButton(
      enabled: enabled,
      tooltip: title,
      onSelected: onSelected,
      child: _OverflowActionChip(
        icon: icon,
        title: title,
        enabled: enabled,
        maxWidth: maxWidth,
        trailing: Icon(Icons.arrow_drop_down, size: 18, color: cs.outline),
      ),
    );
  }
}

class _PanelChoiceChip extends StatelessWidget {
  const _PanelChoiceChip({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _OverflowActionChip(
      icon: icon,
      title: title,
      selected: selected,
      onTap: onTap,
      trailing: selected ? Icon(Icons.check, size: 16, color: cs.primary) : null,
    );
  }
}

class _OverflowActionChip extends StatelessWidget {
  const _OverflowActionChip({
    required this.icon,
    required this.title,
    this.enabled = true,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.maxWidth,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected ? cs.primary : cs.outlineVariant;
    final backgroundColor = selected
        ? cs.primary.withValues(alpha: 0.08)
        : cs.surfaceContainerLow;
    final foregroundColor = enabled ? cs.onSurface : cs.onSurfaceVariant;
    final iconColor = selected ? cs.primary : cs.onSurfaceVariant;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 152),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: foregroundColor,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
