part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// G. Recent Activity Feed
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentActivitiesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '近期活动',
          trailing: GestureDetector(
            onTap: () => GoRouter.of(context).go('/events'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('全部',
                    style: TextStyle(
                        fontSize: 11, color: CofferColors.actionPrimary)),
                Icon(Icons.chevron_right,
                    size: 14, color: CofferColors.actionPrimary),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CofferColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CofferColors.border, width: 0.5),
          ),
          child: async.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: CofferColors.actionPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox(
              height: 120,
              child: Center(
                child: Icon(Icons.error_outline, color: CofferColors.textMuted),
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: CofferSpacing.xl,
                    horizontal: CofferSpacing.base,
                  ),
                  child: Center(
                    child: Text(
                      '暂无活动',
                      style: TextStyle(
                        fontSize: 12,
                        color: CofferColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              final display = events.length > 3 ? events.sublist(0, 3) : events;
              return Column(
                children: [
                  for (var i = 0; i < display.length; i++) ...[
                    _ActivityTile(event: display[i]),
                    if (i < display.length - 1)
                      const Divider(
                          height: 0.5,
                          color: CofferColors.border,
                          thickness: 0.5),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event});
  final DomainEvent event;

  static const _modelIcon = <RelatedModel, IconData>{
    RelatedModel.account: Icons.account_balance_outlined,
    RelatedModel.asset: Icons.show_chart_outlined,
    RelatedModel.card: Icons.credit_card_outlined,
    RelatedModel.channel: Icons.swap_horiz_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).go('/events'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CofferSpacing.base,
          vertical: CofferSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CofferColors.surface3,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                _modelIcon[event.relatedModel] ?? Icons.event_note_outlined,
                size: 16,
                color: CofferColors.textSecondary,
              ),
            ),
            const SizedBox(width: CofferSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CofferColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.relatedModel.labelZh} · ${_fmtRelative(event.triggerTime)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CofferColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CofferSpacing.sm),
            _statusBadge(event.status),
          ],
        ),
      ),
    );
  }

  static Widget _statusBadge(EventStatus s) {
    final (label, variant) = switch (s) {
      EventStatus.pending => ('待处理', StatusVariant.neutral),
      EventStatus.triggered => ('已触发', StatusVariant.warning),
      EventStatus.resolved => ('已处理', StatusVariant.positive),
      EventStatus.closed => ('已关闭', StatusVariant.muted),
    };
    return CofferStatusBadge(label: label, variant: variant);
  }

  static String _fmtRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    final l = t.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)}';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Today's rate-alerts banner
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 仅在「今天」存在 RATE_ALERT 事件时渲染的醒目提示条。
/// 单行展示：预警总数 + 最新一条的币对 / 描述；点击跳转事件中心。
class _TodaysAlertsBanner extends ConsumerWidget {
  const _TodaysAlertsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todaysRateAlertsProvider);
    final list = async.value ?? const <DomainEvent>[];
    if (list.isEmpty) return const SizedBox.shrink();

    final latest = list.first;
    final latestPair = latest.relatedId;
    // sourceKey 形如 RATE_ALERT:{pairKey}:{yyyymmdd}:{kind}
    String kindLabel = '触发';
    final k = latest.sourceKey;
    if (k != null) {
      final parts = k.split(':');
      if (parts.isNotEmpty) {
        final last = parts.last;
        kindLabel = switch (last) {
          'high' => '触及上沿',
          'low' => '跌破下沿',
          'change' => '日内波动',
          _ => '触发',
        };
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: CofferSpacing.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/events'),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: CofferSpacing.base, vertical: CofferSpacing.md),
          decoration: BoxDecoration(
            color: CofferColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: CofferColors.warning.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 18, color: CofferColors.warning),
              const SizedBox(width: CofferSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日汇率预警 · ${list.length} 条',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CofferColors.warning,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '最近: $latestPair · $kindLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CofferColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CofferSpacing.sm),
              const Icon(Icons.chevron_right,
                  size: 18, color: CofferColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
