import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../app/widgets/app_top_bar.dart';
import '../../../core/ui/async_value_view.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../search/presentation/global_search_delegate.dart';
import '../../../core/ui/coffer_empty_state.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/coffer_number_text.dart';
import '../../../core/ui/horizontal_swipe_action.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../domain/entities/dict_type.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/watched_pair.dart';
import 'exchange_rate_providers.dart';
import 'pair_detail_page.dart';
import 'rate_sparkline.dart';

class ExchangeRateListPage extends ConsumerStatefulWidget {
  const ExchangeRateListPage({super.key});

  @override
  ConsumerState<ExchangeRateListPage> createState() =>
      _ExchangeRateListPageState();
}

class _ExchangeRateListPageState extends ConsumerState<ExchangeRateListPage> {
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
    openGlobalSearch(context: context, ref: ref, current: SearchFeature.rates);
  }

  Future<void> _openPairManager() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const _WatchedPairsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pairs = ref.watch(watchedPairListProvider);
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('汇率'),
        showAppIcon: true,
        actions: [
          IconButton(
            tooltip: '管理币对',
            onPressed: _openPairManager,
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: CofferAsyncValueView<List<WatchedPair>>(
        value: pairs,
        onRetry: () => ref.invalidate(watchedPairListProvider),
        isEmpty: (list) => list.isEmpty,
        empty: (_, _) => const CofferEmptyState(
          icon: Icons.currency_exchange,
          title: '还没有关注的币对',
          subtitle: '点右上「管理币对」添加，再从「更多 → 数据同步」拉取最新数据',
        ),
        data: (_, list) {
          return ReorderableListView(
            buildDefaultDragHandles: false,
            padding: EdgeInsets.only(
              bottom: FloatingNavLayout.totalFloatingHeight(context) + 24,
            ),
            header: Column(
              children: [
                _RatesSummaryCard(pairs: list),
                const SizedBox(height: CofferSpacing.sm),
              ],
            ),
            children: [
              for (var i = 0; i < list.length; i++)
                ReorderableDelayedDragStartListener(
                  index: i,
                  key: ValueKey('rate-${list[i].pairKey}'),
                  child: _PairRateCard(pair: list[i]),
                ),
            ],
            onReorderItem: (oldIndex, newIndex) async {
              final reordered = [...list];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final result = await ref
                  .read(manageWatchedPairUseCaseProvider)
                  .reorder(
                    reordered.map((e) => e.pairKey).toList(growable: false),
                  );
              if (!context.mounted) return;
              result.when(
                ok: (_) {},
                err: (e) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('重排失败：${errorToMessage(e)}')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Page summary
// ──────────────────────────────────────────────────────────────

class _RatesSummaryCard extends ConsumerWidget {
  const _RatesSummaryCard({required this.pairs});

  final List<WatchedPair> pairs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = pairs
        .map((pair) => ref.watch(pairRateSeriesProvider(pair.pairKey)))
        .map(_pairSeriesSummaryFromAsync)
        .toList(growable: false);

    final ready = summaries.whereType<_PairSeriesSummary>().toList();
    final withData = ready.where((s) => s.hasData).toList();
    final noDataCount = ready.where((s) => !s.hasData).length;
    final upCount = withData.where((s) => s.changePct > 0).length;
    final downCount = withData.where((s) => s.changePct < 0).length;
    final flatCount = withData.where((s) => s.changePct == 0).length;

    final latestUpdatedAt = ready
        .map((s) => s.updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, current) {
          if (latest == null) return current;
          return current.isAfter(latest) ? current : latest;
        });

    final maxSwing = withData.fold<double>(0, (current, item) {
      final abs = item.changePct.abs();
      return abs > current ? abs : current;
    });

    final total = pairs.length;
    final hasAnySwing = withData.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        CofferSpacing.base,
        CofferSpacing.xs,
        CofferSpacing.base,
        0,
      ),
      padding: const EdgeInsets.all(CofferSpacing.base),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + update time
          Row(
            children: [
              const Text(
                '汇率总览',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CofferColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                latestUpdatedAt == null
                    ? '暂无数据'
                    : '更新于 ${_fmtRelativeTime(latestUpdatedAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: CofferColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$total 个关注币对',
            style: const TextStyle(
              fontFamily: CofferTypo.monoFont,
              fontFeatures: CofferTypo.tabularFigures,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CofferColors.textPrimary,
            ),
          ),
          const SizedBox(height: CofferSpacing.md),
          // Breadth bar
          if (total > 0)
            _BreadthBar(
              up: upCount,
              down: downCount,
              flat: flatCount,
              noData: noDataCount,
              total: total,
            ),
          const SizedBox(height: CofferSpacing.sm),
          // Legend + max swing
          Row(
            children: [
              _legendLabel(CofferColors.positive, '$upCount 涨'),
              const SizedBox(width: CofferSpacing.md),
              _legendLabel(CofferColors.negative, '$downCount 跌'),
              if (flatCount > 0) ...[
                const SizedBox(width: CofferSpacing.md),
                _legendLabel(CofferColors.textMuted, '$flatCount 持平'),
              ],
              if (noDataCount > 0) ...[
                const SizedBox(width: CofferSpacing.md),
                _legendLabel(CofferColors.borderStrong, '$noDataCount 无数据'),
              ],
              const Spacer(),
              const Icon(
                Icons.show_chart,
                size: 14,
                color: CofferColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                hasAnySwing ? displayPercentDouble(maxSwing) : '—',
                style: TextStyle(
                  fontFamily: CofferTypo.monoFont,
                  fontFeatures: CofferTypo.tabularFigures,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasAnySwing
                      ? _swingColor(maxSwing)
                      : CofferColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _legendLabel(Color color, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CofferColors.textSecondary,
        ),
      ),
    ],
  );
}

Color _swingColor(double pct) {
  if (pct > 1) return CofferColors.positive;
  if (pct < -1) return CofferColors.negative;
  return CofferColors.textSecondary;
}

class _BreadthBar extends StatelessWidget {
  const _BreadthBar({
    required this.up,
    required this.down,
    required this.flat,
    required this.noData,
    required this.total,
  });

  final int up;
  final int down;
  final int flat;
  final int noData;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (up > 0)
              Expanded(
                flex: up,
                child: Container(color: CofferColors.positive),
              ),
            if (down > 0)
              Expanded(
                flex: down,
                child: Container(color: CofferColors.negative),
              ),
            if (flat > 0)
              Expanded(
                flex: flat,
                child: Container(color: CofferColors.borderStrong),
              ),
            if (noData > 0)
              Expanded(
                flex: noData,
                child: Container(color: CofferColors.surface2),
              ),
          ],
        ),
      ),
    );
  }
}

class _PairSeriesSummary {
  const _PairSeriesSummary({
    required this.changePct,
    required this.updatedAt,
    required this.hasData,
  });

  final double changePct;
  final DateTime? updatedAt;
  final bool hasData;
}

_PairSeriesSummary? _pairSeriesSummaryFromAsync(
  AsyncValue<List<ExchangeRate>> async,
) {
  return async.maybeWhen(
    data: (series) {
      if (series.isEmpty) return null;
      if (series.length < 2) {
        return _PairSeriesSummary(
          changePct: 0,
          updatedAt: series.last.updatedAt,
          hasData: false,
        );
      }
      final first = series.first.rate.toDouble();
      final last = series.last.rate.toDouble();
      final changePct = first == 0 ? 0.0 : (last - first) / first * 100;
      return _PairSeriesSummary(
        changePct: changePct,
        updatedAt: series.last.updatedAt,
        hasData: true,
      );
    },
    orElse: () => null,
  );
}

// ──────────────────────────────────────────────────────────────
// Shared currency flag pair
// ──────────────────────────────────────────────────────────────

class _CurrencyFlags extends ConsumerWidget {
  const _CurrencyFlags({required this.base, required this.quote});

  final String base;
  final String quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagMap = ref.watch(currencyFlagProvider);
    String flag(String code) => flagMap[code] ?? code;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag(base), style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(flag(quote), style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Pair rate card (card-wrapped, larger sparkline)
// ──────────────────────────────────────────────────────────────

class _PairRateCard extends ConsumerWidget {
  const _PairRateCard({required this.pair});

  final WatchedPair pair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(pairRateSeriesProvider(pair.pairKey));
    return series.when(
      loading: () => _skeleton(context),
      error: (e, _) => _skeleton(context, errorText: '加载失败'),
      data: (list) => _buildCard(context, list),
    );
  }

  Widget _skeleton(BuildContext context, {String? errorText}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CofferSpacing.base,
        vertical: 3,
      ),
      padding: const EdgeInsets.all(CofferSpacing.sm),
      decoration: _cardDeco,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${pair.pairKey}  ${errorText ?? '加载中...'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CofferColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<ExchangeRate> series) {
    final hasData = series.isNotEmpty;
    final latest = hasData ? series.last : null;
    final first = hasData ? series.first : null;
    final points = series.map((e) => e.rate.toDouble()).toList(growable: false);

    Decimal? changePct;
    if (hasData && series.length >= 2) {
      final a = first!.rate;
      final b = latest!.rate;
      if (a != Decimal.zero) {
        changePct = Money.percent(b - a, a);
      }
    }
    final isUp = changePct == null || changePct >= Decimal.zero;
    final sign = changePct == null
        ? ValueSign.neutral
        : (isUp ? ValueSign.positive : ValueSign.negative);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CofferSpacing.base,
        vertical: 3,
      ),
      child: Material(
        color: CofferColors.surface1,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => PairDetailPage(pairKey: pair.pairKey),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: CofferColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(CofferSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CurrencyFlags(
                  base: pair.baseCurrency,
                  quote: pair.quoteCurrency,
                ),
                const SizedBox(width: CofferSpacing.sm),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pair.pairKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CofferColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        latest == null ? '暂无数据' : _fmtTime(latest.updatedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CofferColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CofferSpacing.sm),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: RateSparkline(
                      points: points,
                      isUp: isUp,
                      width: double.infinity,
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(width: CofferSpacing.sm),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          latest == null
                              ? '—'
                              : _fmtRate(latest.rate.toDouble()),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: CofferTypo.monoFont,
                            fontFeatures: CofferTypo.tabularFigures,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CofferColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: CofferNumberText(
                          value: changePct == null
                              ? '—'
                              : displayPercent(changePct, alwaysShowSign: true),
                          sign: sign,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          showIcon: changePct != null,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) => _fmtRelativeTime(t);

  String _fmtRate(double v) => displayDouble(v);
}

final _cardDeco = BoxDecoration(
  color: CofferColors.surface1,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: CofferColors.border, width: 0.5),
);

String _fmtRelativeTime(DateTime t) {
  final l = t.toLocal();
  final now = DateTime.now();
  final diff = now.difference(l);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  String p(int n) => n.toString().padLeft(2, '0');
  return '${l.month}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
}

// ──────────────────────────────────────────────────────────────
// Watched pairs manager page
// ──────────────────────────────────────────────────────────────

class _WatchedPairsPage extends ConsumerStatefulWidget {
  const _WatchedPairsPage();

  @override
  ConsumerState<_WatchedPairsPage> createState() => _WatchedPairsPageState();
}

class _WatchedPairsPageState extends ConsumerState<_WatchedPairsPage> {
  @override
  Widget build(BuildContext context) {
    final pairs = ref.watch(watchedPairListProvider);
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('管理币对'),
        actions: [
          IconButton(
            tooltip: '添加币对',
            onPressed: () => _openAddSheet(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: pairs.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CofferColors.actionPrimary),
        ),
        error: (e, _) => CofferEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(watchedPairListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const CofferEmptyState(
              icon: Icons.currency_exchange,
              title: '还没有关注的币对',
              subtitle: '添加后，从「更多 → 数据同步」一次性拉取所有币对',
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            buildDefaultDragHandles: false,
            itemCount: list.length,
            onReorderItem: (oldIndex, newIndex) async {
              final reordered = [...list];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final result = await ref
                  .read(manageWatchedPairUseCaseProvider)
                  .reorder(
                    reordered.map((e) => e.pairKey).toList(growable: false),
                  );
              if (!context.mounted) return;
              result.when(
                ok: (_) {},
                err: (e) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('重排失败：${errorToMessage(e)}')),
                ),
              );
            },
            itemBuilder: (_, i) => _PairTile(
              key: ValueKey('pair-${list[i].pairKey}'),
              pair: list[i],
              reorderIndex: i,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const _PairEditorSheet(),
    );
  }
}

class _PairTile extends ConsumerWidget {
  const _PairTile({super.key, required this.pair, required this.reorderIndex});

  final WatchedPair pair;
  final int reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CofferSpacing.base,
        vertical: CofferSpacing.xs,
      ),
      child: Material(
        color: CofferColors.surface1,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => PairDetailPage(pairKey: pair.pairKey),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: CofferColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: CofferSpacing.base,
              vertical: CofferSpacing.md,
            ),
            child: Row(
              children: [
                _CurrencyFlags(
                  base: pair.baseCurrency,
                  quote: pair.quoteCurrency,
                ),
                const SizedBox(width: CofferSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair.pairKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CofferColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${pair.baseCurrency} → ${pair.quoteCurrency}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CofferColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '移除',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: CofferColors.negative,
                  ),
                  onPressed: () async {
                    final r = await ref
                        .read(manageWatchedPairUseCaseProvider)
                        .remove(pair.pairKey);
                    if (!context.mounted) return;
                    r.when(
                      ok: (_) {},
                      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('移除失败：${errorToMessage(e)}')),
                      ),
                    );
                  },
                ),
                ReorderableDelayedDragStartListener(
                  index: reorderIndex,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_handle,
                      color: CofferColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PairEditorSheet extends ConsumerStatefulWidget {
  const _PairEditorSheet();

  @override
  ConsumerState<_PairEditorSheet> createState() => _PairEditorSheetState();
}

class _PairEditorSheetState extends ConsumerState<_PairEditorSheet> {
  String _baseCurrency = 'USD';
  String _quoteCurrency = 'CNY';
  bool _busy = false;
  String? _errorMsg;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _errorMsg = null;
    });
    final r = await ref
        .read(manageWatchedPairUseCaseProvider)
        .add(baseCurrency: _baseCurrency, quoteCurrency: _quoteCurrency);
    if (!mounted) return;
    setState(() => _busy = false);
    r.when(
      ok: (_) => Navigator.pop(context),
      err: (e) => setState(() => _errorMsg = errorToMessage(e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '添加币对',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CofferColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DictPickerField(
                  key: const Key('pair-editor-base-currency-field'),
                  type: DictType.currency,
                  value: _baseCurrency,
                  label: '基准币种',
                  textStyle: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _baseCurrency = v);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.swap_horiz,
                  color: CofferColors.textMuted,
                  size: 20,
                ),
              ),
              Expanded(
                child: DictPickerField(
                  key: const Key('pair-editor-quote-currency-field'),
                  type: DictType.currency,
                  value: _quoteCurrency,
                  label: '报价币种',
                  textStyle: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _quoteCurrency = v);
                  },
                ),
              ),
            ],
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMsg!,
              style: const TextStyle(
                fontSize: 13,
                color: CofferColors.negative,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
