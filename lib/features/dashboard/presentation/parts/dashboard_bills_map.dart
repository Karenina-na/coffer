part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// E. Upcoming Credit Bills (horizontal strip)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _UpcomingBillsSection extends ConsumerWidget {
  const _UpcomingBillsSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingBillsProvider);
    final list = async.value ?? const <UpcomingBill>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '即将到来的账单',
          trailing: GestureDetector(
            onTap: () => GoRouter.of(context).go('/cards'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('全部',
                    style: TextStyle(
                        fontSize: 11, color: GwpColors.actionPrimary)),
                Icon(Icons.chevron_right,
                    size: 14, color: GwpColors.actionPrimary),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: HorizontalGestureGuard(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: GwpSpacing.sm),
              itemBuilder: (_, i) => _BillCard(bill: list[i]),
            ),
          ),
        ),
        const SizedBox(height: GwpSpacing.xl),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill});
  final UpcomingBill bill;

  @override
  Widget build(BuildContext context) {
    final card = bill.card;
    final isPayment = bill.kind == BillKind.paymentDue;
    final urgent = bill.daysFromNow <= 3;
    final accent = isPayment
        ? (urgent ? GwpColors.negative : GwpColors.warning)
        : GwpColors.info;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(GwpSpacing.md),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPayment ? '还款日' : '账单日',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                bill.daysFromNow == 0
                    ? '今天'
                    : bill.daysFromNow == 1
                        ? '明天'
                        : '${bill.daysFromNow}天',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: urgent ? GwpColors.negative : GwpColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.sm),
          Text(
            card.issuerName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GwpColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            card.cardNoMasked,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontSize: 11,
              color: GwpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}


