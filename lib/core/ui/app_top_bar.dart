import 'package:flutter/material.dart';

import 'base_currency_switcher.dart';
import 'settings_action.dart';
import 'sync_status_pill.dart';
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
  /// 是否在左侧显示应用图标（主 Tab 页使用）。
  final bool showAppIcon;

  /// 顶部栏高度。Flutter 默认 `kToolbarHeight = 56`；用户反馈顶部有多余空白，
  /// 在保证 44dp 可触达下限的基础上压到 44，进一步贴近内容。
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
    // 分级阈值：
    // - compact：常见窄屏（小屏手机竖屏），压缩右侧分隔与间距
    // - tiny：极窄（横屏或超小屏），title 空间会被严重挤压
    final compact = width < 380;
    final tiny = width < 340;
    // 用 Flexible 包裹 title，保证 actions 过多时至少显示省略号而不是被整段裁掉
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.asset(
                      'assets/branding/app_icon_gold.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            : null);
    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: compact ? 8 : null,
      title: wrappedTitle,
      leading: effectiveLeading,
      automaticallyImplyLeading: effectiveLeading == null && automaticallyImplyLeading,
      bottom: bottom,
      actions: [
        ...actions,
        if (actions.isNotEmpty && showFixedActions && !tiny)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
            child: VerticalDivider(
              width: 1,
              indent: 14,
              endIndent: 14,
              color: cs.outlineVariant,
            ),
          ),
        if (showFixedActions) ...[
          const SyncStatusPill(),
          if (!compact) const SizedBox(width: 4),
          const BaseCurrencySwitcher(),
          const TopSearchAction(),
          const SettingsAction(),
          if (!compact) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
