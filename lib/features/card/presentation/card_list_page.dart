import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/global_search_delegate.dart';
import '../../../core/ui/gwp_empty_state.dart';
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

/// 卡片列表排序维度。
///
/// 默认 [expiry]：已过期 / 即将到期的卡置顶，方便用户快速续卡。
enum _CardSort { expiry, createdDesc, issuer, type }

extension on _CardSort {
  String get label => switch (this) {
        _CardSort.expiry => '按到期日（紧急优先）',
        _CardSort.createdDesc => '按创建时间（新）',
        _CardSort.issuer => '按发卡行',
        _CardSort.type => '按卡类型',
      };
}

class CardListPage extends ConsumerStatefulWidget {
  const CardListPage({super.key});

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  _CardSort _sort = _CardSort.expiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(topSearchOpenerProvider.notifier).set(_openSearch);
    });
  }

  @override
  void dispose() {
    ref.read(topSearchOpenerProvider.notifier).set(null);
    super.dispose();
  }

  void _openSearch() {
    openGlobalSearch(
      context: context,
      ref: ref,
      current: SearchFeature.cards,
    );
  }

  List<BankCard> _applySort(List<BankCard> input) {
    final list = [...input];
    switch (_sort) {
      case _CardSort.expiry:
        // 到期紧急度排序：expired → critical → warn → none，内部按 daysLeft 升序
        // （已过期天数更久的放后面，即将到期天数更少的放前面）
        list.sort((a, b) {
          final ea = ExpirySignal.of(a);
          final eb = ExpirySignal.of(b);
          final pa = _toneWeight(ea.tone);
          final pb = _toneWeight(eb.tone);
          if (pa != pb) return pa.compareTo(pb);
          return ea.daysLeft.compareTo(eb.daysLeft);
        });
      case _CardSort.createdDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _CardSort.issuer:
        list.sort((a, b) => a.issuerName.compareTo(b.issuerName));
      case _CardSort.type:
        list.sort((a, b) {
          final t = a.cardType.code.compareTo(b.cardType.code);
          if (t != 0) return t;
          return a.issuerName.compareTo(b.issuerName);
        });
    }
    return list;
  }

  static int _toneWeight(ExpiryTone t) => switch (t) {
        ExpiryTone.expired => 0,
        ExpiryTone.critical => 1,
        ExpiryTone.warn => 2,
        ExpiryTone.none => 3,
      };

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardListProvider);
    final accounts = ref.watch(accountListProvider);
    final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
    final byId = <String, Account>{
      for (final a in accounts.value ?? const <Account>[]) a.id: a,
    };
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('卡片'),
        showAppIcon: true,
        actions: [
          PopupMenuButton<_CardSort>(
            tooltip: '排序',
            icon: const Icon(Icons.swap_vert),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              for (final m in _CardSort.values)
                PopupMenuItem(
                  value: m,
                  child: Row(
                    children: [
                      Icon(
                        m == _sort
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: m == _sort ? GwpColors.actionPrimary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(m.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/cards/new'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('新建'),
        ),
      ),
      body: cards.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(cardListProvider),
        ),
        data: (raw) {
          if (raw.isEmpty) {
            return const GwpEmptyState(
              icon: Icons.credit_card_outlined,
              title: '还没有卡片',
              subtitle: '点击右下角按钮添加第一张卡',
            );
          }
          final sorted = _applySort(raw);
          final summary = _summarize(raw);
          return CustomScrollView(
            slivers: [
              if (summary != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: summary,
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                sliver: SliverList.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final c = sorted[i];
                    final acc = byId[c.accountId];
                    return WalletCardTile(
                      card: c,
                      account: acc,
                      regionMeta: regionMetaOf(regionIndex, acc?.sovereigntyRegion ?? ''),
                      onTap: () => CardDetailSheet.show(
                        context,
                        card: c,
                        account: acc,
                      ),
                    );
                  },
                ),
              ),
            ],
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
    final color = expired > 0 ? GwpColors.negative : GwpColors.warning;
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
