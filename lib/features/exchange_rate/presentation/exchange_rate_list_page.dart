import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../../core/ui/global_search_delegate.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_heat_strip.dart';
import '../../../core/ui/gwp_number_text.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/exchange_rate_enums.dart';
import '../../../domain/entities/dict_type.dart';
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
  late final TopSearchOpener _topSearchOpener;

  @override
  void initState() {
    super.initState();
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _topSearchOpener.set(_openSearch);
    });
  }

  @override
  void dispose() {
    _topSearchOpener.set(null);
    super.dispose();
  }

  void _openSearch() {
    openGlobalSearch(
      context: context,
      ref: ref,
      current: SearchFeature.rates,
    );
  }

  Future<void> _openEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const _RateEditorSheet(),
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: FloatingNavLayout.totalFloatingHeight(context) + 4,
        ),
        child: FloatingActionButton.extended(
          onPressed: _openEditor,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('录入'),
        ),
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
              subtitle: '点右上「管理币对」添加，再点「拉取最新」同步数据',
            );
          }
          return ListView(
            padding: EdgeInsets.only(
              bottom: FloatingNavLayout.totalFloatingHeight(context) + 24,
            ),
            children: [
              // Heat strip overview card
              _HeatStripCard(pairs: list),
              const SizedBox(height: GwpSpacing.sm),
              // Rate cards
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
// Heat strip overview (card style)
// ──────────────────────────────────────────────────────────────

class _HeatStripCard extends ConsumerWidget {
  const _HeatStripCard({required this.pairs});
  final List<WatchedPair> pairs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        GwpSpacing.base, GwpSpacing.sm, GwpSpacing.base, 0,
      ),
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
              const Icon(Icons.thermostat_outlined,
                  size: 14, color: GwpColors.textMuted),
              const SizedBox(width: 6),
              const Text(
                '7日波动概览',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${pairs.length} 币对',
                style: const TextStyle(
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.sm),
          for (final pair in pairs)
            _HeatStripRow(pairKey: pair.pairKey),
        ],
      ),
    );
  }
}

class _HeatStripRow extends ConsumerWidget {
  const _HeatStripRow({required this.pairKey});
  final String pairKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(pairRateSeriesProvider(pairKey));
    return seriesAsync.when(
      loading: () => const SizedBox(height: 20),
      error: (_, _) => const SizedBox(height: 20),
      data: (series) {
        if (series.length < 2) return const SizedBox(height: 20);
        final first = series.first.rate.toDouble();
        final last = series.last.rate.toDouble();
        final changePct = first != 0 ? (last - first) / first * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  pairKey,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: GwpHeatStrip(
                  value: changePct,
                  maxAbsValue: 1.0,
                  label:
                      '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                ),
              ),
            ],
          ),
        );
      },
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
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.xs,
      ),
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: _cardDeco,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair.pairKey,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorText ?? '加载中...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: GwpColors.textMuted,
                  ),
                ),
              ],
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

    // 7-day high/low
    double? high;
    double? low;
    if (points.length >= 2) {
      high = points.reduce((a, b) => a > b ? a : b);
      low = points.reduce((a, b) => a < b ? a : b);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.xs,
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
            padding: const EdgeInsets.all(GwpSpacing.base),
            child: Column(
              children: [
                // Top row: pair name + rate + change
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: pair key + currency labels
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pair.pairKey,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: GwpColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latest == null
                                ? '暂无数据'
                                : _fmtTime(latest.updatedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: GwpColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right: rate value + change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          latest == null
                              ? '—'
                              : _fmtRate(latest.rate.toDouble()),
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GwpColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GwpNumberText(
                          value: changePct == null
                              ? '—'
                              : '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                          sign: sign,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          showIcon: changePct != null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: GwpSpacing.md),
                // Sparkline (wider + taller)
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: RateSparkline(
                    points: points,
                    isUp: isUp,
                    width: double.infinity,
                    height: 48,
                  ),
                ),
                // H/L row
                if (high != null && low != null) ...[
                  const SizedBox(height: GwpSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(label: '7日高', value: _fmtRate(high)),
                      _StatChip(label: '7日低', value: _fmtRate(low)),
                      _StatChip(
                        label: '振幅',
                        value: low > 0 && high - low > 0
                            ? '${((high - low) / low * 100).toStringAsFixed(2)}%'
                            : '—',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    final now = DateTime.now();
    final diff = now.difference(l);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.month}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
  }

  String _fmtRate(double v) {
    if (v >= 100) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontFeatures: GwpTypo.tabularFigures,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: GwpColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

final _cardDeco = BoxDecoration(
  color: GwpColors.surface1,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: GwpColors.border, width: 0.5),
);

// ──────────────────────────────────────────────────────────────
// Rate editor bottom sheet (unchanged logic)
// ──────────────────────────────────────────────────────────────

class _RateEditorSheet extends ConsumerStatefulWidget {
  const _RateEditorSheet();

  @override
  ConsumerState<_RateEditorSheet> createState() => _RateEditorSheetState();
}

class _RateEditorSheetState extends ConsumerState<_RateEditorSheet> {
  String _baseCurrency = 'USD';
  String _quoteCurrency = 'CNY';
  final _rateCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'manual');
  SnapshotType _snapshot = SnapshotType.realtime;
  bool _busy = false;
  String? _errorMsg;

  @override
  void dispose() {
    _rateCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final base = _baseCurrency.trim().toUpperCase();
    final quote = _quoteCurrency.trim().toUpperCase();
    final rate = Decimal.tryParse(_rateCtrl.text.trim());
    if (base.isEmpty ||
        quote.isEmpty ||
        rate == null ||
        rate <= Decimal.zero) {
      setState(() => _errorMsg = '请填写有效的币种与汇率（> 0）');
      return;
    }
    if (base == quote) {
      setState(() => _errorMsg = '基准与报价不能相同');
      return;
    }
    setState(() {
      _busy = true;
      _errorMsg = null;
    });
    final r = await ref.read(saveManualRateUseCaseProvider)(
          baseCurrency: base,
          quoteCurrency: quote,
          rate: rate,
          snapshotType: _snapshot,
          source: _sourceCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.isErr) {
      setState(() => _errorMsg = errorToMessage(r.errorOrNull!));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
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
            '录入汇率快照',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GwpColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DictPickerField(
                key: const Key('rate-editor-base-currency-field'),
                type: DictType.currency,
                value: _baseCurrency,
                label: '基准币种',
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
                key: const Key('rate-editor-quote-currency-field'),
                type: DictType.currency,
                value: _quoteCurrency,
                label: '报价币种',
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _quoteCurrency = v);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _rateCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: '汇率',
              helperText: '1 单位基准币可兑换的报价币数量',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SnapshotType>(
            initialValue: _snapshot,
            decoration: const InputDecoration(labelText: '快照类型'),
            dropdownColor: GwpColors.surface2,
            items: SnapshotType.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.labelBilingual)))
                .toList(),
            onChanged: (v) => setState(() => _snapshot = v ?? _snapshot),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sourceCtrl,
            decoration: const InputDecoration(labelText: '来源'),
          ),
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
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Watched pairs manager page
// ──────────────────────────────────────────────────────────────

class _WatchedPairsPage extends ConsumerWidget {
  const _WatchedPairsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = ref.watch(watchedPairListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('管理币对')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('添加币对'),
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
              subtitle: '添加后，点汇率页右上的「拉取最新」一次性拉取所有币对',
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

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
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
          const SizedBox(height: 4),
          const Text(
            'Frankfurter 支持 33 种 ECB 币种（USD/EUR/CNY/JPY/GBP/HKD 等）',
            style: TextStyle(
              fontSize: 12,
              color: GwpColors.textMuted,
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
