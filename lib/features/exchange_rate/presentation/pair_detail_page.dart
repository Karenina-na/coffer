import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_heat_strip.dart';
import '../../../core/ui/gwp_mini_chart.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/exchange_rate_enums.dart';
import '../../../domain/entities/watched_pair.dart';
import '../../../domain/valuation/asset_valuator.dart';
import 'exchange_rate_providers.dart';

// ──────────────────────────────────────────────────────────────
// Snapshot type labels
// ──────────────────────────────────────────────────────────────

const _snapshotTypeLabels = <SnapshotType, String>{
  SnapshotType.realtime: '实时',
  SnapshotType.hourly: '小时',
  SnapshotType.daily: '日频',
};

// ──────────────────────────────────────────────────────────────
// Value formatters
// ──────────────────────────────────────────────────────────────

String _fmtRate(double v) {
  if (v >= 100) return v.toStringAsFixed(2);
  if (v >= 1) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}

String _heroRate(double v) {
  // Preserve full precision in hero display.
  if (v >= 1000) return v.toStringAsFixed(2);
  if (v >= 100) return v.toStringAsFixed(3);
  if (v >= 1) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}

String _fmtDate(DateTime t) {
  final l = t.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${p(l.month)}-${p(l.day)}';
}

String _fmtDateTime(DateTime t) {
  final l = t.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
}

String _shortDate(DateTime t) {
  final l = t.toLocal();
  return '${l.month}/${l.day}';
}

// ──────────────────────────────────────────────────────────────
// Main page
// ──────────────────────────────────────────────────────────────

/// 币对详情页：沿用资产/账户详情页的 Section 卡片 + Hero 模式。
class PairDetailPage extends ConsumerStatefulWidget {
  const PairDetailPage({super.key, required this.pairKey});

  final String pairKey;

  @override
  ConsumerState<PairDetailPage> createState() => _PairDetailPageState();
}

class _PairDetailPageState extends ConsumerState<PairDetailPage> {
  int _rangeDays = 7;
  bool _fetching = false;

  static const _ranges = [
    (7, '7日'),
    (30, '1月'),
    (90, '3月'),
    (365, '1年'),
    (0, '全部'),
  ];

  String get _base {
    final parts = widget.pairKey.split('/');
    return parts.isNotEmpty ? parts[0] : widget.pairKey;
  }

  String get _quote {
    final parts = widget.pairKey.split('/');
    return parts.length >= 2 ? parts[1] : '';
  }

  Future<void> _fetchRange(SyncMode mode) async {
    if (_fetching) return;
    setState(() => _fetching = true);

    final parts = widget.pairKey.split('/');
    if (parts.length != 2) {
      if (mounted) setState(() => _fetching = false);
      return;
    }
    final base = parts[0];
    final quote = parts[1];
    final provider = ref.read(frankfurterProviderProvider);
    final repo = ref.read(exchangeRateRepositoryProvider);
    final now = DateTime.now();
    const uuid = Uuid();

    try {
      if (mode == SyncMode.incremental) {
        final r = await provider.fetchLatest(base: base, symbols: [quote]);
        if (!mounted) return;
        await r.when(
          ok: (snap) async {
            final rate = snap.rates[quote];
            if (rate != null) {
              await repo.upsert(ExchangeRate(
                id: uuid.v4(),
                pairKey: widget.pairKey,
                baseCurrency: base,
                quoteCurrency: quote,
                rate: rate,
                asOfTime: snap.date,
                updatedAt: now,
                source: 'frankfurter',
                snapshotType: SnapshotType.daily,
              ));
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('最新汇率已同步')),
              );
            }
          },
          err: (e) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('拉取失败：${errorToMessage(e)}')),
              );
            }
          },
        );
      } else {
        final to = DateTime(now.year, now.month, now.day);
        final from = _rangeDays <= 0
            ? to.subtract(const Duration(days: 365 * 5))
            : to.subtract(Duration(days: _rangeDays + 2));
        final r = await provider.fetchTimeSeries(
          base: base,
          symbols: [quote],
          from: from,
          to: to,
        );
        if (!mounted) return;
        await r.when(
          ok: (ts) async {
            for (final day in ts.series) {
              final rate = day.value[quote];
              if (rate == null) continue;
              await repo.upsert(ExchangeRate(
                id: uuid.v4(),
                pairKey: widget.pairKey,
                baseCurrency: base,
                quoteCurrency: quote,
                rate: rate,
                asOfTime: day.key,
                updatedAt: now,
                source: 'frankfurter',
                snapshotType: SnapshotType.daily,
              ));
              if (!mounted) return;
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已拉取 ${ts.series.length} 天数据')),
              );
            }
          },
          err: (e) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('拉取失败：${errorToMessage(e)}')),
              );
            }
          },
        );
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _openAlertEditor() async {
    final list = await ref.read(watchedPairRepositoryProvider).listAll();
    final pair = list.where((p) => p.pairKey == widget.pairKey).firstOrNull;
    if (pair == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该币对未被关注，无法设置预警')),
        );
      }
      return;
    }
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GwpColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RateAlertEditorSheet(pair: pair),
    );
    if (saved == true && mounted) {
      ref.invalidate(watchedPairListProvider);
    }
  }

  _Coverage _coverage(List<ExchangeRate> list, int days) {
    if (list.isEmpty) return _Coverage.empty;
    if (days <= 0) return _Coverage.ok;
    // Provider 已用 since = today - days 过滤，list 中 earliest >= since。
    // 判断覆盖充分性：earliest 距窗口起点 since 在 slack 天内即视为 OK，
    // slack 用于吸收 Frankfurter 在周末/节假日的缺口（最多连休 4 天）。
    const slack = 4;
    final now = DateTime.now();
    final windowStart =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final threshold = windowStart.add(const Duration(days: slack));
    final earliest = list.first.asOfTime;
    if (earliest.isAfter(threshold)) return _Coverage.insufficient;
    return _Coverage.ok;
  }

  @override
  Widget build(BuildContext context) {
    final query = PairSeriesQuery(
      pairKey: widget.pairKey,
      rangeDays: _rangeDays,
    );
    final series = ref.watch(pairSeriesByRangeProvider(query));
    // Full history (for hero sparkline / heat map) — always 30 days.
    final headSeries =
        ref.watch(pairRateSeriesProvider(widget.pairKey));

    return Scaffold(
      backgroundColor: GwpColors.canvas,
      appBar: AppBar(
        title: Text(widget.pairKey),
        backgroundColor: GwpColors.canvas,
        foregroundColor: GwpColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '编辑预警',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _fetching ? null : _openAlertEditor,
          ),
          PopupMenuButton<SyncMode>(
            tooltip: '同步汇率',
            enabled: !_fetching,
            icon: _fetching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GwpColors.actionPrimary,
                    ),
                  )
                : const Icon(Icons.sync),
            onSelected: (mode) => _fetchRange(mode),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SyncMode.incremental,
                child: ListTile(
                  leading: Icon(Icons.update),
                  title: Text('增量同步（仅最新汇率）'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: SyncMode.full,
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('全量同步（区间序列）'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: series.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(pairSeriesByRangeProvider(query)),
        ),
        data: (list) {
          final coverage = _coverage(list, _rangeDays);
          final recent7d = headSeries.maybeWhen(
            data: (d) => d,
            orElse: () => const <ExchangeRate>[],
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _PairHero(
                pairKey: widget.pairKey,
                base: _base,
                quote: _quote,
                series: list,
                recent: recent7d,
              ),
              const SizedBox(height: GwpSpacing.base),
              // ── Price Chart Section ──
              _SectionCard(
                icon: Icons.candlestick_chart_outlined,
                title: '汇率走势',
                children: [
                  _RangeSelector(
                    ranges: _ranges,
                    current: _rangeDays,
                    onSelected: (v) => setState(() => _rangeDays = v),
                  ),
                  if (coverage != _Coverage.ok)
                    _CoverageBanner(coverage: coverage),
                  const SizedBox(height: GwpSpacing.sm),
                  SizedBox(
                    height: 240,
                    child: _PriceChart(series: list),
                  ),
                  const SizedBox(height: GwpSpacing.md),
                  _RangeStats(series: list),
                ],
              ),
              const SizedBox(height: GwpSpacing.md),
              // ── Volatility Heat Map ──
              _SectionCard(
                icon: Icons.waves_outlined,
                title: '近 7 日波动',
                children: [
                  _VolatilityHeat(
                    series: recent7d.isNotEmpty ? recent7d : list,
                  ),
                ],
              ),
              const SizedBox(height: GwpSpacing.md),
              // ── Currency Details ──
              _SectionCard(
                icon: Icons.info_outline,
                title: '币对信息',
                children: [
                  _CurrencyDetails(
                    base: _base,
                    quote: _quote,
                    series: list,
                  ),
                ],
              ),
              const SizedBox(height: GwpSpacing.md),
              // ── Rate History Timeline ──
              _SectionCard(
                icon: Icons.history,
                title: '历史快照',
                children: [
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '暂无数据，点右上「同步」拉取',
                        style: TextStyle(
                          fontSize: 13,
                          color: GwpColors.textMuted,
                        ),
                      ),
                    )
                  else
                    _HistoryTimeline(series: list),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _Coverage { ok, insufficient, empty }

// ──────────────────────────────────────────────────────────────
// Section card wrapper
// ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: GwpSpacing.base),
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: GwpColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textSecondary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: GwpSpacing.sm),
            child: Divider(height: 1, color: GwpColors.border),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 1) Pair Hero
// ──────────────────────────────────────────────────────────────

class _PairHero extends StatelessWidget {
  const _PairHero({
    required this.pairKey,
    required this.base,
    required this.quote,
    required this.series,
    required this.recent,
  });

  final String pairKey;
  final String base;
  final String quote;
  final List<ExchangeRate> series;
  final List<ExchangeRate> recent;

  @override
  Widget build(BuildContext context) {
    final latest = series.isNotEmpty ? series.last : null;
    double? changeAbs;
    double? changePct;
    if (series.length >= 2) {
      final prev = series[series.length - 2].rate.toDouble();
      final curr = series.last.rate.toDouble();
      changeAbs = curr - prev;
      if (prev != 0) changePct = changeAbs / prev * 100;
    }
    final isUp = (changeAbs ?? 0) >= 0;
    final changeColor = changeAbs == null
        ? GwpColors.textMuted
        : (isUp ? GwpColors.positive : GwpColors.negative);

    // Accent color based on direction (neutral blue if no change).
    final accent = changeAbs == null
        ? GwpColors.actionPrimary
        : (isUp ? GwpColors.positive : GwpColors.negative);

    // Sparkline: prefer 7-day window; fallback to last 30 points of series.
    final sparkSource = recent.isNotEmpty ? recent : series;
    final sparkData = sparkSource.length >= 2
        ? sparkSource
            .skip(max(0, sparkSource.length - 30))
            .map((p) => p.rate.toDouble())
            .toList()
        : <double>[];

    // Range (min/max) over current series for KPI chips.
    double? seriesHigh;
    double? seriesLow;
    if (series.isNotEmpty) {
      final vals = series.map((e) => e.rate.toDouble());
      seriesHigh = vals.reduce(max);
      seriesLow = vals.reduce(min);
    }

    // 国旗 emoji 在未内置 emoji 字体的 Android 设备上会退化成字母，造成
    // Hero 区排版错位，已改用文字块。

    return Container(
      margin: const EdgeInsets.fromLTRB(
        GwpSpacing.base,
        GwpSpacing.sm,
        GwpSpacing.base,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            GwpColors.surface1,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(GwpSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: currency tile + pair code + snapshot type badge
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      base,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      width: 22,
                      height: 0.7,
                      color: accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      quote,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: GwpColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GwpSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pairKey,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 $base = ? $quote',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GwpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GwpColors.surface2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _snapshotTypeLabels[latest.snapshotType] ??
                        latest.snapshotType.labelZh,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GwpSpacing.lg),
          // Hero rate row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前汇率',
                      style: TextStyle(
                        fontSize: 11,
                        color: GwpColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest == null
                          ? '—'
                          : _heroRate(latest.rate.toDouble()),
                      style: const TextStyle(
                        fontFamily: GwpTypo.monoFont,
                        fontFeatures: GwpTypo.tabularFigures,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$quote / $base',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GwpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Sparkline
              if (sparkData.length >= 2)
                GwpMiniChart(
                  data: sparkData,
                  width: 96,
                  height: 40,
                ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          // Change row
          Row(
            children: [
              if (changeAbs != null) ...[
                Icon(
                  isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: changeColor,
                ),
                Text(
                  '${isUp ? '+' : ''}${changeAbs.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp ? GwpColors.positiveBg : GwpColors.negativeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    changePct != null
                        ? '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                        : '—',
                    style: TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ),
              ] else
                const Text(
                  '需要更多数据点',
                  style: TextStyle(fontSize: 12, color: GwpColors.textMuted),
                ),
              const Spacer(),
              if (latest != null)
                Text(
                  _fmtDate(latest.asOfTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: GwpColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          // KPI chips
          Row(
            children: [
              _HeroChip(
                icon: Icons.arrow_upward_outlined,
                label: '区间高',
                value: seriesHigh == null ? '—' : _fmtRate(seriesHigh),
              ),
              const SizedBox(width: GwpSpacing.sm),
              _HeroChip(
                icon: Icons.arrow_downward_outlined,
                label: '区间低',
                value: seriesLow == null ? '—' : _fmtRate(seriesLow),
              ),
              const SizedBox(width: GwpSpacing.sm),
              _HeroChip(
                icon: Icons.cloud_outlined,
                label: '数据源',
                value: latest?.source ?? '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.sm,
          vertical: GwpSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: GwpColors.surface2.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: GwpColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: GwpColors.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontFeatures: GwpTypo.tabularFigures,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Range selector
// ──────────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.ranges,
    required this.current,
    required this.onSelected,
  });

  final List<(int, String)> ranges;
  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in ranges) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(r.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: r.$1 == current
                      ? GwpColors.actionPrimary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: r.$1 == current
                      ? Border.all(
                          color:
                              GwpColors.actionPrimary.withValues(alpha: 0.4),
                          width: 0.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  r.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        r.$1 == current ? FontWeight.w600 : FontWeight.w400,
                    color: r.$1 == current
                        ? GwpColors.actionPrimary
                        : GwpColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (r != ranges.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Coverage banner
// ──────────────────────────────────────────────────────────────

class _CoverageBanner extends StatelessWidget {
  const _CoverageBanner({required this.coverage});
  final _Coverage coverage;

  @override
  Widget build(BuildContext context) {
    final msg = coverage == _Coverage.empty
        ? '暂无快照数据，点击右上「同步」拉取'
        : '当前区间缺少早段数据，点击右上「同步」补齐';
    return Container(
      margin: const EdgeInsets.only(top: GwpSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GwpColors.warningBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GwpColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: GwpColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 11,
                color: GwpColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 2) Price chart (fl_chart)
// ──────────────────────────────────────────────────────────────

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.series});
  final List<ExchangeRate> series;

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return Center(
        child: Text(
          series.isEmpty ? '暂无数据，点击右上「同步」拉取' : '仅 1 个数据点，无法绘图',
          style: const TextStyle(fontSize: 13, color: GwpColors.textMuted),
        ),
      );
    }
    final values = series.map((p) => p.rate.toDouble()).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    final isUp = values.last >= values.first;
    final lineColor = isUp ? GwpColors.positive : GwpColors.negative;

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i]),
    ];

    final yMin = range > 0 ? minV - range * 0.05 : minV - 1;
    final yMax = range > 0 ? maxV + range * 0.05 : maxV + 1;

    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface2.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 4),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minY: yMin,
                maxY: yMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range > 0 ? range / 3 : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: GwpColors.border.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _fmtRate(value),
                            style: const TextStyle(
                              fontSize: 9,
                              color: GwpColors.textMuted,
                              fontFamily: GwpTypo.monoFont,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _xInterval(series.length),
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _shortDate(series[idx].asOfTime),
                            style: const TextStyle(
                              fontSize: 8,
                              color: GwpColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => GwpColors.surface3,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((s) {
                      final idx = s.x.toInt().clamp(0, series.length - 1);
                      final p = series[idx];
                      return LineTooltipItem(
                        '${_fmtDate(p.asOfTime)}\n${_fmtRate(p.rate.toDouble())}',
                        TextStyle(
                          fontFamily: GwpTypo.monoFont,
                          fontSize: 11,
                          color: lineColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (_, spots) => spots
                      .map((_) => TouchedSpotIndicatorData(
                            FlLine(
                              color: lineColor.withValues(alpha: 0.4),
                              strokeWidth: 1,
                              dashArray: [3, 2],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (_, _, _, _) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: lineColor,
                                strokeWidth: 2,
                                strokeColor: GwpColors.surface1,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: values.first,
                      color: GwpColors.textMuted.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 3],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.2),
                          lineColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 52),
              Text(
                _fmtDate(series.first.asOfTime),
                style:
                    const TextStyle(fontSize: 9, color: GwpColors.textMuted),
              ),
              Text(
                _fmtDate(series.last.asOfTime),
                style:
                    const TextStyle(fontSize: 9, color: GwpColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 30) return 7;
    if (count <= 90) return 14;
    if (count <= 365) return 60;
    return 90;
  }
}

// ──────────────────────────────────────────────────────────────
// 3) Range stats (4 mini stat cards)
// ──────────────────────────────────────────────────────────────

class _RangeStats extends StatelessWidget {
  const _RangeStats({required this.series});
  final List<ExchangeRate> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final values = series.map((p) => p.rate.toDouble()).toList();
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    double variance = 0;
    for (final v in values) {
      variance += (v - avg) * (v - avg);
    }
    final std = variance / values.length;
    final vol = avg == 0 ? 0.0 : (std > 0 ? (sqrt(std) / avg * 100) : 0.0);

    return Row(
      children: [
        _MiniStatCard(
          icon: Icons.arrow_upward_outlined,
          iconColor: GwpColors.positive,
          label: '区间高',
          value: _fmtRate(high),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.arrow_downward_outlined,
          iconColor: GwpColors.negative,
          label: '区间低',
          value: _fmtRate(low),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.trending_flat_outlined,
          iconColor: GwpColors.info,
          label: '均值',
          value: _fmtRate(avg),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.show_chart_outlined,
          iconColor: GwpColors.warning,
          label: '波动率',
          value: '${vol.toStringAsFixed(2)}%',
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.xs,
          vertical: GwpSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GwpColors.surface2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: GwpColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 4) Volatility heat map (7-day)
// ──────────────────────────────────────────────────────────────

class _VolatilityHeat extends StatelessWidget {
  const _VolatilityHeat({required this.series});
  final List<ExchangeRate> series;

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '数据不足，无法计算日涨跌',
          style: TextStyle(fontSize: 12, color: GwpColors.textMuted),
        ),
      );
    }
    // Compute daily percentage changes (tail up to 7 entries).
    final pts = series.length > 8
        ? series.sublist(series.length - 8)
        : series;
    final rows = <(DateTime, double)>[];
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1].rate.toDouble();
      if (prev == 0) continue;
      final pct = (pts[i].rate.toDouble() - prev) / prev * 100;
      rows.add((pts[i].asOfTime, pct));
    }
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '数据不足，无法计算日涨跌',
          style: TextStyle(fontSize: 12, color: GwpColors.textMuted),
        ),
      );
    }
    final maxAbs = rows.map((r) => r.$2.abs()).reduce(max);
    final scale = maxAbs > 0 ? maxAbs : 1.0;

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    _shortDate(r.$1),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 11,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: GwpHeatStrip(
                    value: r.$2,
                    maxAbsValue: scale,
                    label:
                        '${r.$2 >= 0 ? '+' : ''}${r.$2.toStringAsFixed(2)}%',
                    height: 8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 5) Currency details (key-value grid)
// ──────────────────────────────────────────────────────────────

class _CurrencyDetails extends StatelessWidget {
  const _CurrencyDetails({
    required this.base,
    required this.quote,
    required this.series,
  });

  final String base;
  final String quote;
  final List<ExchangeRate> series;

  @override
  Widget build(BuildContext context) {
    final latest = series.isNotEmpty ? series.last : null;
    final earliest = series.isNotEmpty ? series.first : null;
    final rows = <(String, String)>[
      ('基准币种', base),
      ('报价币种', quote),
      ('币对代码', '$base/$quote'),
      if (latest != null) ('数据源', latest.source),
      if (latest != null)
        (
          '快照类型',
          _snapshotTypeLabels[latest.snapshotType] ?? latest.snapshotType.labelZh
        ),
      if (latest != null) ('最新时间', _fmtDateTime(latest.asOfTime)),
      if (latest != null) ('最近更新', _fmtDateTime(latest.updatedAt)),
      if (earliest != null) ('最早记录', _fmtDate(earliest.asOfTime)),
      ('数据点数', series.length.toString()),
    ];
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _KvRow(k: rows[i].$1, v: rows[i].$2),
          if (i < rows.length - 1)
            const Divider(height: 1, color: GwpColors.border),
        ],
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.k, required this.v});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 12,
                color: GwpColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 12,
                color: GwpColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 6) History timeline
// ──────────────────────────────────────────────────────────────

class _HistoryTimeline extends StatefulWidget {
  const _HistoryTimeline({required this.series});
  final List<ExchangeRate> series;

  @override
  State<_HistoryTimeline> createState() => _HistoryTimelineState();
}

class _HistoryTimelineState extends State<_HistoryTimeline> {
  static const _previewLimit = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final recent = widget.series.reversed.toList();
    final visible = _showAll ? recent : recent.take(_previewLimit).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++)
          _HistoryRow(
            rate: visible[i],
            prev: i < visible.length - 1 ? visible[i + 1] : null,
            isFirst: i == 0,
          ),
        if (!_showAll && recent.length > _previewLimit)
          GestureDetector(
            onTap: () => setState(() => _showAll = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                '展开全部 ${recent.length} 条',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: GwpColors.actionPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.rate,
    required this.prev,
    required this.isFirst,
  });
  final ExchangeRate rate;
  final ExchangeRate? prev;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    double? changePct;
    if (prev != null) {
      final p = prev!.rate.toDouble();
      if (p != 0) {
        changePct = (rate.rate.toDouble() - p) / p * 100;
      }
    }
    final isUp = (changePct ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Timeline dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst
                  ? GwpColors.actionPrimary
                  : GwpColors.textMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: GwpSpacing.sm),
          // Date
          SizedBox(
            width: 80,
            child: Text(
              _fmtDate(rate.asOfTime),
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 11,
                color: GwpColors.textSecondary,
              ),
            ),
          ),
          // Rate
          Expanded(
            child: Text(
              _fmtRate(rate.rate.toDouble()),
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GwpColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: GwpSpacing.sm),
          // Change badge
          SizedBox(
            width: 60,
            child: changePct == null
                ? const SizedBox.shrink()
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isUp
                          ? GwpColors.positiveBg
                          : GwpColors.negativeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontFamily: GwpTypo.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUp
                            ? GwpColors.positive
                            : GwpColors.negative,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Rate alert editor sheet
// ──────────────────────────────────────────────────────────────

class _RateAlertEditorSheet extends ConsumerStatefulWidget {
  const _RateAlertEditorSheet({required this.pair});
  final WatchedPair pair;

  @override
  ConsumerState<_RateAlertEditorSheet> createState() =>
      _RateAlertEditorSheetState();
}

class _RateAlertEditorSheetState
    extends ConsumerState<_RateAlertEditorSheet> {
  late final TextEditingController _highCtrl;
  late final TextEditingController _lowCtrl;
  late final TextEditingController _pctCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    String fmt(Decimal? v) => v == null ? '' : _stripTrailingZeros(v);
    _highCtrl = TextEditingController(text: fmt(widget.pair.thresholdHigh));
    _lowCtrl = TextEditingController(text: fmt(widget.pair.thresholdLow));
    _pctCtrl = TextEditingController(text: fmt(widget.pair.alertChangePct));
  }

  static String _stripTrailingZeros(Decimal v) {
    var s = v.toString();
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  void dispose() {
    _highCtrl.dispose();
    _lowCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  Decimal? _parse(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return Decimal.tryParse(t);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final high = _parse(_highCtrl.text);
    final low = _parse(_lowCtrl.text);
    final pct = _parse(_pctCtrl.text);
    setState(() => _saving = true);
    final r = await ref.read(watchedPairRepositoryProvider).updateThresholds(
          pairKey: widget.pair.pairKey,
          thresholdHigh: high,
          thresholdLow: low,
          alertChangePct: pct,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    r.when(
      ok: (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('预警阈值已保存')),
        );
      },
      err: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：${errorToMessage(e)}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          GwpSpacing.base, GwpSpacing.base, GwpSpacing.base, viewInsets + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 18, color: GwpColors.actionPrimary),
                const SizedBox(width: 8),
                Text(
                  '预警设置 · ${widget.pair.pairKey}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: GwpColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: GwpSpacing.xs),
            const Text(
              '留空即取消该项。任何一项触发都会写入一条 RATE_ALERT 事件，'
              '每天同一币对同一类型至多一次。',
              style: TextStyle(fontSize: 12, color: GwpColors.textSecondary),
            ),
            const SizedBox(height: GwpSpacing.md),
            _AlertField(
              controller: _highCtrl,
              label: '上沿（rate ≥ 此值触发）',
              hint: '例如 7.3',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return Decimal.tryParse(v.trim()) == null ? '请输入有效数字' : null;
              },
            ),
            const SizedBox(height: GwpSpacing.sm),
            _AlertField(
              controller: _lowCtrl,
              label: '下沿（rate ≤ 此值触发）',
              hint: '例如 6.8',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final x = Decimal.tryParse(v.trim());
                if (x == null) return '请输入有效数字';
                final high = _parse(_highCtrl.text);
                if (high != null && x >= high) return '下沿必须小于上沿';
                return null;
              },
            ),
            const SizedBox(height: GwpSpacing.sm),
            _AlertField(
              controller: _pctCtrl,
              label: '波动幅度（日环比 %，如 3 表示 ±3%）',
              hint: '例如 2.5',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final x = Decimal.tryParse(v.trim());
                if (x == null) return '请输入有效数字';
                if (x <= Decimal.zero) return '需为正数';
                return null;
              },
            ),
            const SizedBox(height: GwpSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: GwpColors.actionPrimary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertField extends StatelessWidget {
  const _AlertField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontFamily: GwpTypo.monoFont, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: GwpTypo.monoFont,
          color: GwpColors.textMuted,
        ),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
