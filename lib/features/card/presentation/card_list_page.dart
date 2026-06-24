import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/app_top_bar.dart';
import '../../../core/ui/async_value_view.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../search/presentation/global_search_delegate.dart';
import '../../../core/ui/coffer_empty_state.dart';
import '../../../core/ui/horizontal_swipe_action.dart';
import '../../../core/ui/region_meta.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../account/presentation/account_providers.dart';
import 'card_detail_sheet.dart';
import 'card_providers.dart';
import 'wallet_card_tile.dart';

class CardListPage extends ConsumerStatefulWidget {
  const CardListPage({super.key});

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  late final HorizontalSwipeAction _horizontalSwipeAction;
  late final TopSearchOpener _topSearchOpener;

  @override
  void initState() {
    super.initState();
    _horizontalSwipeAction = ref.read(horizontalSwipeActionProvider.notifier);
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _horizontalSwipeAction.set(this, null);
      _topSearchOpener.set(this, _openSearch);
    });
  }

  @override
  void dispose() {
    _topSearchOpener.clearLater(this);
    _horizontalSwipeAction.clearLater(this);
    super.dispose();
  }

  void _openSearch() {
    openGlobalSearch(context: context, ref: ref, current: SearchFeature.cards);
  }

  List<BankCard> _orderedCards(List<BankCard> input) => [...input];

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardListProvider);
    final accounts = ref.watch(accountListProvider);
    final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
    final byId = <String, Account>{
      for (final a in accounts.value ?? const <Account>[]) a.id: a,
    };
    return Scaffold(
      appBar: const AppTopBar(title: Text('卡片'), showAppIcon: true),
      body: CofferAsyncValueView<List<BankCard>>(
        value: cards,
        onRetry: () => ref.invalidate(cardListProvider),
        isEmpty: (raw) => raw.isEmpty,
        empty: (_, _) => const CofferEmptyState(
          icon: Icons.credit_card_outlined,
          title: '还没有卡片',
          subtitle: '从右上「更多 → 新建」添加第一张卡',
        ),
        data: (_, raw) {
          final sorted = _orderedCards(raw);
          final summary = _summarize(raw);
          return ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              FloatingNavLayout.totalFloatingHeight(context) + 24,
            ),
            buildDefaultDragHandles: false,
            header: summary == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: summary,
                  ),
            itemCount: sorted.length,
            onReorderItem: (oldIndex, newIndex) async {
              final reordered = [...sorted];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final result = await ref
                  .read(cardRepositoryProvider)
                  .reorder(reordered.map((e) => e.id).toList(growable: false));
              if (result.isErr && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '重排失败：${result.errorOrNull?.message ?? '未知错误'}',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_, i) {
              final c = sorted[i];
              final acc = byId[c.accountId];
              return Padding(
                key: ValueKey('card-${c.id}'),
                padding: const EdgeInsets.only(bottom: 16),
                child: ReorderableDelayedDragStartListener(
                  index: i,
                  child: WalletCardTile(
                    card: c,
                    account: acc,
                    regionMeta: regionMetaOf(
                      regionIndex,
                      acc?.sovereigntyRegion ?? '',
                    ),
                    onTap: () =>
                        CardDetailSheet.show(context, card: c, account: acc),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 扫描全量卡片，如有已过期或 30 天内到期则返回提醒横条，否则返回 null。
  Widget? _summarize(List<BankCard> cards) {
    var expired = 0;
    var soon = 0;
    for (final c in cards) {
      // closed / EXPIRED 状态的卡用户已经知情，不重复告警
      if (c.status == CardStatus.closed) continue;
      final e = ExpirySignal.of(c);
      if (e.tone == ExpiryTone.expired) {
        expired++;
      } else if (e.tone == ExpiryTone.critical) {
        soon++;
      }
    }
    if (expired == 0 && soon == 0) return null;
    final parts = <String>[];
    if (expired > 0) parts.add('$expired 张已过期');
    if (soon > 0) parts.add('$soon 张 30 天内到期');
    final color = expired > 0 ? CofferColors.negative : CofferColors.warning;
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.join(' · '),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
