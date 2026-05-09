import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopBarCreateActionItem {
  const TopBarCreateActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.subtitle,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
  final String? subtitle;
}

final currentTopBarCreateActionsProvider = Provider<List<TopBarCreateActionItem>>(
  (ref) => const <TopBarCreateActionItem>[
    TopBarCreateActionItem(
      id: 'accounts-create',
      label: '账户',
      icon: Icons.account_balance_outlined,
      route: '/accounts/new',
    ),
    TopBarCreateActionItem(
      id: 'assets-create',
      label: '资产',
      icon: Icons.show_chart_outlined,
      route: '/assets/new',
    ),
    TopBarCreateActionItem(
      id: 'cards-create',
      label: '卡片',
      icon: Icons.credit_card_outlined,
      route: '/cards/new',
    ),
    TopBarCreateActionItem(
      id: 'channels-create',
      label: '通道',
      icon: Icons.swap_horiz_outlined,
      route: '/channels/new',
    ),
    TopBarCreateActionItem(
      id: 'events-create',
      label: '事件',
      icon: Icons.event_outlined,
      route: '/events/new',
    ),
  ],
);
