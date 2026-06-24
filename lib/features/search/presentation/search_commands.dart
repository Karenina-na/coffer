import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/presentation/sync_providers.dart';

/// 命令面板中的一条可执行项。通过 `>` 前缀触发。
class SearchCommand {
  const SearchCommand({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon = Icons.chevron_right,
    required this.run,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;

  /// 在关键词匹配/排序时除了 title/subtitle 还会看的额外字段。
  final List<String> keywords;

  final void Function(BuildContext ctx, WidgetRef ref) run;
}

/// 默认命令清单——跨模块跳转 + 新建 + 同步。
List<SearchCommand> defaultSearchCommands() => [
  SearchCommand(
    id: 'nav.dashboard',
    icon: Icons.dashboard_outlined,
    title: '打开 仪表盘',
    subtitle: '查看净资产与 KPI',
    keywords: const ['dashboard', 'home', '首页'],
    run: (ctx, _) => ctx.go('/dashboard'),
  ),
  SearchCommand(
    id: 'nav.holdings',
    icon: Icons.account_balance_wallet_outlined,
    title: '打开 资金',
    subtitle: '账户 / 资产 / 渠道',
    keywords: const ['holdings', 'accounts', 'assets', '账户', '资产'],
    run: (ctx, _) => ctx.go('/holdings'),
  ),
  SearchCommand(
    id: 'nav.events',
    icon: Icons.event_note_outlined,
    title: '打开 事件',
    keywords: const ['events', '日程'],
    run: (ctx, _) => ctx.go('/events'),
  ),
  SearchCommand(
    id: 'nav.rates',
    icon: Icons.currency_exchange_outlined,
    title: '打开 汇率',
    keywords: const ['rates', 'fx', '币对'],
    run: (ctx, _) => ctx.go('/rates'),
  ),
  SearchCommand(
    id: 'nav.cards',
    icon: Icons.credit_card_outlined,
    title: '打开 卡片',
    keywords: const ['cards'],
    run: (ctx, _) => ctx.go('/cards'),
  ),
  SearchCommand(
    id: 'nav.channels',
    icon: Icons.hub_outlined,
    title: '打开 出入金渠道',
    keywords: const ['channels'],
    run: (ctx, _) => ctx.push('/channels'),
  ),
  SearchCommand(
    id: 'nav.topology',
    icon: Icons.polyline_outlined,
    title: '打开 资金拓扑',
    keywords: const ['topology', '拓扑'],
    run: (ctx, _) => ctx.push('/topology'),
  ),
  SearchCommand(
    id: 'nav.backup',
    icon: Icons.backup_outlined,
    title: '打开 备份',
    run: (ctx, _) => ctx.push('/backup'),
  ),
  SearchCommand(
    id: 'nav.settings',
    icon: Icons.settings_outlined,
    title: '打开 设置',
    run: (ctx, _) => ctx.push('/settings'),
  ),
  SearchCommand(
    id: 'new.account',
    icon: Icons.add_circle_outline,
    title: '新建 账户',
    keywords: const ['create', 'new', 'account'],
    run: (ctx, _) => ctx.push('/accounts/new'),
  ),
  SearchCommand(
    id: 'new.asset',
    icon: Icons.add_circle_outline,
    title: '新建 资产',
    keywords: const ['create', 'new', 'asset'],
    run: (ctx, _) => ctx.push('/assets/new'),
  ),
  SearchCommand(
    id: 'new.card',
    icon: Icons.add_circle_outline,
    title: '新建 卡片',
    keywords: const ['create', 'new', 'card'],
    run: (ctx, _) => ctx.push('/cards/new'),
  ),
  SearchCommand(
    id: 'new.channel',
    icon: Icons.add_circle_outline,
    title: '新建 出入金渠道',
    keywords: const ['create', 'new', 'channel'],
    run: (ctx, _) => ctx.push('/channels/new'),
  ),
  SearchCommand(
    id: 'new.event',
    icon: Icons.add_circle_outline,
    title: '新建 事件',
    keywords: const ['create', 'new', 'event'],
    run: (ctx, _) => ctx.push('/events/new'),
  ),
  SearchCommand(
    id: 'sync.full',
    icon: Icons.sync,
    title: '立即同步（全量）',
    subtitle: '刷新汇率 + 行情',
    keywords: const ['sync', 'refresh', '刷新', '同步'],
    run: (ctx, ref) =>
        ref.read(globalRefreshProvider).run(scope: SyncScope.all),
  ),
  SearchCommand(
    id: 'sync.rates',
    icon: Icons.sync,
    title: '立即同步（仅汇率）',
    keywords: const ['sync', 'rates', 'fx'],
    run: (ctx, ref) =>
        ref.read(globalRefreshProvider).run(scope: SyncScope.ratesOnly),
  ),
];
