import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/valuation/asset_valuator.dart';
import '../../features/sync/presentation/sync_providers.dart';
import '../valuation/valuation_currency_provider.dart';
import 'base_currency_switcher.dart';
import 'settings_action.dart';
import 'sync_window_menu_button.dart';
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
                    _PanelSection(
                      icon: _syncIcon(sync),
                      iconColor: _syncColor(context, sync),
                      title: '数据同步',
                      expanded: _syncExpanded,
                      onToggle: () {
                        setState(() => _syncExpanded = !_syncExpanded);
                      },
                      children: [
                        _PanelInfoRow(
                          icon: _syncIcon(sync),
                          title: _syncTitle(sync),
                          subtitle: _syncSubtitle(sync),
                        ),
                        _SyncRangeActionRow(
                          icon: Icons.sync,
                          title: '刷新全部',
                          subtitle: '行情 + 汇率',
                          enabled: !sync.isSyncing,
                          onSelected: (window) =>
                              _runSync(context, ref, scope: SyncScope.all, window: window),
                        ),
                        _SyncRangeActionRow(
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
                        _SyncRangeActionRow(
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
                    const SizedBox(height: 16),
                    _PanelSection(
                      icon: Icons.language,
                      iconColor: Theme.of(context).colorScheme.primary,
                      title: '本位币',
                      expanded: _currencyExpanded,
                      onToggle: () {
                        setState(() => _currencyExpanded = !_currencyExpanded);
                      },
                      children: [
                        _PanelInfoRow(
                          icon: Icons.currency_exchange,
                          title: '当前本位币',
                          subtitle: currentCurrency,
                        ),
                        for (final code in kSupportedBaseCurrencies)
                          _PanelChoiceRow(
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
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

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
            onTap: onToggle,
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
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(height: 1, indent: 56, color: dividerColor),
            ],
          ],
        ],
      ),
    );
  }
}

class _PanelInfoRow extends StatelessWidget {
  const _PanelInfoRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
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

class _SyncRangeActionRow extends StatelessWidget {
  const _SyncRangeActionRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.enabled,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final ValueChanged<SyncWindow> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SyncWindowMenuButton(
      enabled: enabled,
      tooltip: title,
      onSelected: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 16,
                color: enabled ? cs.onSurfaceVariant : cs.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '选择范围',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? cs.primary : cs.outline,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

class _PanelChoiceRow extends StatelessWidget {
  const _PanelChoiceRow({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 16,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
