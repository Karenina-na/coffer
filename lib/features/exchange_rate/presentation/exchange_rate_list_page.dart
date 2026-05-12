import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../../core/ui/global_search_delegate.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_kpi_tile.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/gwp_number_text.dart';
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
    openGlobalSearch(
      context: context,
      ref: ref,
      current: SearchFeature.rates,
    );
  }

  Future<void> _openPairManager() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const _WatchedPairsPage()),
    );
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
      body: pairs.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(watchedPairListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const GwpEmptyState(
              icon: Icons.currency_exchange,
              title: '还没有关注的币对',
              subtitle: '点右上「管理币对」添加，再从「更多 → 数据同步」拉取最新数据',
            );
          }
          return ListView(
            padding: EdgeInsets.only(
              bottom: FloatingNavLayout.totalFloatingHeight(context) + 24,
            ),
            children: [
              _RatesSummaryCard(pairs: list),
              const SizedBox(height: GwpSpacing.sm),
              for (final pair in list)
                _PairRateCard(pair: pair),
            ],
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
    final ready = summaries.whereType<_PairSeriesSummary>().toList(growable: false);
    final upCount = ready.where((item) => item.changePct > 0).length;
    final downCount = ready.where((item) => item.changePct < 0).length;
    final neutralCount = pairs.length - upCount - downCount;
    final latestUpdatedAt = ready
        .map((item) => item.updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, current) {
          if (latest == null) return current;
          return current.isAfter(latest) ? current : latest;
        });
    final maxSwing = ready.fold<double>(0, (current, item) {
      final abs = item.changePct.abs();
      return abs > current ? abs : current;
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(
        GwpSpacing.base,
        GwpSpacing.xs,
        GwpSpacing.base,
        0,
      ),
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatesOverviewHeader(
            pairCount: pairs.length,
            upCount: upCount,
            downCount: downCount,
            latestUpdatedAt: latestUpdatedAt,
          ),
          const SizedBox(height: GwpSpacing.base),
          _RatesOverviewGrid(
            pairCount: pairs.length,
            upCount: upCount,
            downCount: downCount,
            neutralCount: neutralCount,
            maxSwing: ready.isEmpty ? null : maxSwing,
          ),
        ],
      ),
    );
  }
}

class _RatesOverviewHeader extends StatelessWidget {
  const _RatesOverviewHeader({
    required this.pairCount,
    required this.upCount,
    required this.downCount,
    required this.latestUpdatedAt,
  });

  final int pairCount;
  final int upCount;
  final int downCount;
  final DateTime? latestUpdatedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '汇率总览',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$pairCount 个关注币对',
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GwpColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$upCount 涨 / $downCount 跌',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: GwpColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '最近更新',
                style: TextStyle(
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                latestUpdatedAt == null ? '暂无数据' : _fmtRelativeTime(latestUpdatedAt!),
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatesOverviewGrid extends StatelessWidget {
  const _RatesOverviewGrid({
    required this.pairCount,
    required this.upCount,
    required this.downCount,
    required this.neutralCount,
    required this.maxSwing,
  });

  final int pairCount;
  final int upCount;
  final int downCount;
  final int neutralCount;
  final double? maxSwing;

  @override
  Widget build(BuildContext context) {
    final swing = maxSwing;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _RatesOverviewTile(
                icon: Icons.swap_horiz,
                label: '币对数',
                value: '$pairCount',
                iconColor: GwpColors.actionPrimary,
              ),
            ),
            const SizedBox(width: GwpSpacing.sm),
            Expanded(
              child: _RatesOverviewTile(
                icon: Icons.trending_up,
                label: '上涨',
                value: '$upCount',
                iconColor: GwpColors.positive,
              ),
            ),
          ],
        ),
        const SizedBox(height: GwpSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _RatesOverviewTile(
                icon: Icons.trending_down,
                label: '下跌',
                value: '$downCount',
                iconColor: GwpColors.negative,
                subtitle: neutralCount > 0 ? '$neutralCount 个待同步' : null,
              ),
            ),
            const SizedBox(width: GwpSpacing.sm),
            Expanded(
              child: _RatesOverviewTile(
                icon: Icons.show_chart,
                label: '最大波动',
                value: swing == null ? '—' : displayPercentDouble(swing),
                iconColor: GwpColors.info,
                subtitle: swing == null ? '尚无足够数据' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatesOverviewTile extends StatelessWidget {
  const _RatesOverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GwpKpiTile(
      icon: icon,
      label: label,
      value: value,
      subtitle: subtitle,
      iconColor: iconColor,
    );
  }
}

class _PairSeriesSummary {
  const _PairSeriesSummary({
    required this.changePct,
    required this.updatedAt,
  });

  final double changePct;
  final DateTime? updatedAt;
}

_PairSeriesSummary? _pairSeriesSummaryFromAsync(AsyncValue<List<ExchangeRate>> async) {
  return async.maybeWhen(
    data: (series) {
      if (series.length < 2) return null;
      final first = series.first.rate.toDouble();
      final last = series.last.rate.toDouble();
      final changePct = first == 0 ? 0.0 : (last - first) / first * 100;
      return _PairSeriesSummary(
        changePct: changePct,
        updatedAt: series.last.updatedAt,
      );
    },
    orElse: () => null,
  );
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
        horizontal: GwpSpacing.base,
        vertical: 3,
      ),
      padding: const EdgeInsets.all(GwpSpacing.sm),
      decoration: _cardDeco,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${pair.pairKey}  ${errorText ?? '加载中...'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: GwpColors.textMuted,
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
    final points =
        series.map((e) => e.rate.toDouble()).toList(growable: false);

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
        horizontal: GwpSpacing.base,
        vertical: 3,
      ),
      child: Material(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (_) => PairDetailPage(pairKey: pair.pairKey),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: GwpColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(GwpSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                          color: GwpColors.textPrimary,
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
                          color: GwpColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
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
                const SizedBox(width: GwpSpacing.sm),
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
                          latest == null ? '—' : _fmtRate(latest.rate.toDouble()),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GwpColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: GwpNumberText(
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
  color: GwpColors.surface1,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: GwpColors.border, width: 0.5),
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
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(watchedPairListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const GwpEmptyState(
              icon: Icons.currency_exchange,
              title: '还没有关注的币对',
              subtitle: '添加后，从「更多 → 数据同步」一次性拉取所有币对',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: list.length,
            itemBuilder: (_, i) => _PairTile(pair: list[i]),
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
  const _PairTile({required this.pair});

  final WatchedPair pair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.xs,
      ),
      child: Material(
        color: GwpColors.surface1,
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
              border: Border.all(color: GwpColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: GwpSpacing.base,
              vertical: GwpSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: GwpColors.surface3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.sync_alt_outlined,
                      size: 18, color: GwpColors.textSecondary),
                ),
                const SizedBox(width: GwpSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair.pairKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GwpColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${pair.baseCurrency} → ${pair.quoteCurrency}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: GwpColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '移除',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: GwpColors.negative),
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
    final r = await ref.read(manageWatchedPairUseCaseProvider).add(
          baseCurrency: _baseCurrency,
          quoteCurrency: _quoteCurrency,
        );
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
              color: GwpColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
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
              child: Icon(Icons.swap_horiz, color: GwpColors.textMuted, size: 20),
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
          ]),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMsg!,
              style: const TextStyle(
                fontSize: 13,
                color: GwpColors.negative,
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
