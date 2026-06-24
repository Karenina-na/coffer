part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// B. KPI Grid
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({
    required this.summary,
    required this.onAccountsTap,
    required this.onCardsTap,
    required this.onEventsTap,
  });

  final WealthSummary summary;
  final VoidCallback onAccountsTap;
  final VoidCallback onCardsTap;
  final VoidCallback onEventsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(dashboardKpiProvider);

    return kpiAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: CofferColors.actionPrimary),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (kpi) {
        final missing = summary.missingAssetIds.length;
        return Row(
          children: [
            Expanded(
              child: CofferKpiTile(
                icon: missing > 0
                    ? Icons.warning_amber_outlined
                    : Icons.account_balance_outlined,
                label: '账户',
                value: '${summary.accountCount}',
                subtitle: missing > 0
                    ? '$missing 条缺汇率'
                    : '${kpi.regionSet.length} 个地区',
                iconColor: missing > 0
                    ? CofferColors.warning
                    : CofferColors.actionPrimary,
                onTap: onAccountsTap,
              ),
            ),
            const SizedBox(width: CofferSpacing.sm),
            Expanded(
              child: CofferKpiTile(
                icon: Icons.credit_card_outlined,
                label: '卡片',
                value: '${kpi.cardCount}',
                subtitle: kpi.creditCardCount > 0
                    ? '${kpi.creditCardCount} 张信用卡 · 已用 ${(kpi.creditUsedRatio * 100).toStringAsFixed(0)}%'
                    : '无信用卡',
                iconColor: kpi.creditUsedRatio > 0.8
                    ? CofferColors.negative
                    : CofferColors.actionPrimary,
                onTap: onCardsTap,
              ),
            ),
            const SizedBox(width: CofferSpacing.sm),
            Expanded(
              child: CofferKpiTile(
                icon: Icons.notification_important_outlined,
                label: '待处理事件',
                value: '${kpi.pendingEventCount}',
                subtitle: kpi.criticalEventCount > 0
                    ? '${kpi.criticalEventCount} 条紧急'
                    : '无紧急',
                iconColor: kpi.criticalEventCount > 0
                    ? CofferColors.negative
                    : CofferColors.actionPrimary,
                onTap: onEventsTap,
              ),
            ),
          ],
        );
      },
    );
  }
}
