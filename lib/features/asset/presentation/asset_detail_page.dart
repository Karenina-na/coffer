import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors.dart';
import '../../../core/money/money.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../../core/result.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_mini_chart.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../core/ui/sync_window_menu_button.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/usecases/value_assets_in_currency.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../../domain/usecases/transfer_asset.dart';
import '../../account/presentation/account_providers.dart';
import 'asset_providers.dart';
import 'transfer_asset_dialog.dart';

// ──────────────────────────────────────────────────────────────
// Asset type → icon / color
// ──────────────────────────────────────────────────────────────

const _typeIcons = <AssetType, IconData>{
  AssetType.stock: Icons.show_chart,
  AssetType.equity: Icons.business,
  AssetType.fund: Icons.pie_chart_outline,
  AssetType.bond: Icons.receipt_long,
  AssetType.cd: Icons.savings,
  AssetType.option: Icons.call_split,
  AssetType.future: Icons.trending_up,
  AssetType.warrant: Icons.description_outlined,
  AssetType.policy: Icons.shield_outlined,
  AssetType.crypto: Icons.currency_bitcoin,
  AssetType.perpetual: Icons.loop,
  AssetType.contract: Icons.handshake_outlined,
  AssetType.preciousMetal: Icons.diamond_outlined,
  AssetType.fxAsset: Icons.currency_exchange,
};

const _typeColors = <AssetType, Color>{
  AssetType.stock: Color(0xFF64748B),
  AssetType.equity: Color(0xFF6366F1),
  AssetType.fund: Color(0xFF22C55E),
  AssetType.bond: Color(0xFFF59E0B),
  AssetType.cd: Color(0xFFA78BFA),
  AssetType.option: Color(0xFFFF6B6B),
  AssetType.future: Color(0xFF845EC2),
  AssetType.warrant: Color(0xFFD65DB1),
  AssetType.policy: Color(0xFF00C9A7),
  AssetType.crypto: Color(0xFFEC4899),
  AssetType.perpetual: Color(0xFFC34A36),
  AssetType.contract: Color(0xFF008F7A),
  AssetType.preciousMetal: Color(0xFFDAA520),
  AssetType.fxAsset: Color(0xFF38BDF8),
};

// ──────────────────────────────────────────────────────────────
// Value formatters
// ──────────────────────────────────────────────────────────────
// heroFormat / compactValue 已提取到 lib/core/ui/format_utils.dart

String _fmtPrice(double v) => displayDouble(v);

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

String _assetTypeLabel(AssetType t) {
  return switch (t) {
    AssetType.stock => '股票',
    AssetType.equity => '股权',
    AssetType.fund => '基金',
    AssetType.bond => '债券',
    AssetType.cd => '存单',
    AssetType.option => '期权',
    AssetType.future => '期货',
    AssetType.warrant => '权证',
    AssetType.policy => '保单',
    AssetType.crypto => '加密资产',
    AssetType.perpetual => '永续合约',
    AssetType.contract => '合约',
    AssetType.preciousMetal => '贵金属',
    AssetType.fxAsset => '外汇',
  };
}

String _assetStatusLabel(AssetStatus s) {
  return switch (s) {
    AssetStatus.holding => '持有中',
    AssetStatus.frozen => '已冻结',
    AssetStatus.redeemed => '已赎回',
    AssetStatus.closed => '已清仓',
  };
}

StatusVariant _statusVariant(AssetStatus s) {
  return switch (s) {
    AssetStatus.holding => StatusVariant.positive,
    AssetStatus.frozen => StatusVariant.warning,
    AssetStatus.redeemed => StatusVariant.info,
    AssetStatus.closed => StatusVariant.muted,
  };
}

// ──────────────────────────────────────────────────────────────
// Main page
// ──────────────────────────────────────────────────────────────

class AssetDetailPage extends ConsumerStatefulWidget {
  const AssetDetailPage({super.key, required this.assetId});
  final String assetId;

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  int _rangeDays = 7;
  bool _fetchingLatest = false;
  bool _fetchingHistory = false;

  static const _ranges = [
    (7, '7日'),
    (30, '1月'),
    (90, '3月'),
    (365, '1年'),
    (0, '全部'),
  ];

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(assetByIdProvider(widget.assetId));
    final valuedAsync = ref.watch(valuedAssetByIdProvider(widget.assetId));
    final historyAsync = ref.watch(
      assetValuationHistoryProvider(widget.assetId),
    );

    return Scaffold(
      backgroundColor: GwpColors.canvas,
      appBar: AppBar(
        title: const Text('资产详情'),
        backgroundColor: GwpColors.canvas,
        foregroundColor: GwpColors.textPrimary,
        elevation: 0,
        actions: [
          SyncWindowMenuButton(
            tooltip: '同步当前资产',
            enabled: !(_fetchingLatest || _fetchingHistory),
            onSelected: (window) => _syncRange(context, window),
            child: (_fetchingLatest || _fetchingHistory)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GwpColors.actionPrimary,
                    ),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: '手动输入价格',
            onPressed: () => _promptUpdatePrice(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: '更多操作',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => _onMoreAction(v, assetAsync.asData?.value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('编辑资产'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('删除资产', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: assetAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(assetByIdProvider(widget.assetId)),
        ),
        data: (asset) {
          if (asset == null) {
            return const GwpEmptyState(
              icon: Icons.show_chart_outlined,
              title: '资产不存在或已删除',
              subtitle: '该资产可能已被移除',
            );
          }
          final accountAsync = ref.watch(accountByIdProvider(asset.accountId));
          final account = accountAsync.asData?.value;
          final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
          final valuationCurrency = ref.watch(valuationCurrencyProvider);
          final allPoints = _extractPoints(historyAsync.asData?.value ?? const []);
          final filtered = _filterByRange(allPoints, _rangeDays);
          final coverage = _coverage(filtered, _rangeDays);
          return valuedAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: GwpColors.actionPrimary),
            ),
            error: (e, _) => GwpEmptyState.error(
              message: '加载计价值失败: ${errorToMessage(e)}',
              onRetry: () => ref.invalidate(valuedAssetByIdProvider(widget.assetId)),
            ),
            data: (valuedAsset) => ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _AssetHero(
                  asset: asset,
                  valuedAsset: valuedAsset,
                  valuationCurrency: valuationCurrency,
                  points: filtered,
                ),
                const SizedBox(height: GwpSpacing.base),
                _SectionCard(
                  icon: Icons.show_chart,
                  title: '价格走势',
                  children: [
                    _RangeSelector(
                      current: _rangeDays,
                      ranges: _ranges,
                      onSelected: (d) => setState(() => _rangeDays = d),
                    ),
                    _CoverageBanner(coverage: coverage),
                    SizedBox(
                      height: 180,
                      child: _PriceChart(
                        points: filtered,
                        currency: asset.currency,
                      ),
                    ),
                    _RangeStats(points: filtered),
                  ],
                ),
                const SizedBox(height: GwpSpacing.md),
                _SectionCard(
                  icon: Icons.analytics_outlined,
                  title: '持仓分析',
                  children: [
                    _HoldingAnalysis(
                      asset: asset,
                      valuedAsset: valuedAsset,
                      valuationCurrency: valuationCurrency,
                    ),
                  ],
                ),
                const SizedBox(height: GwpSpacing.md),
                _SectionCard(
                  icon: Icons.account_balance_outlined,
                  title: '关联账户',
                  children: [
                    _AccountLinkCard(
                      asset: asset,
                      account: account,
                      accountRegionLabel: account == null
                          ? null
                          : regionLabel(regionIndex, account.sovereigntyRegion),
                    ),
                  ],
                ),
                const SizedBox(height: GwpSpacing.md),
                _SectionCard(
                  icon: Icons.info_outline,
                  title: '基本信息',
                  children: [_BasicInfoCard(asset: asset)],
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: GwpSpacing.md),
                  _SectionCard(
                    icon: Icons.history,
                    title: '估值历史',
                    children: [
                      _HistoryTimeline(points: filtered, currency: asset.currency),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _onMoreAction(String action, Asset? asset) {
    if (asset == null) return;
    switch (action) {
      case 'edit':
        context.push('/assets/${asset.id}/edit');
      case 'delete':
        _confirmDelete(asset);
      case 'transfer':
        _promptTransfer(asset);
    }
  }

  Future<void> _confirmDelete(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除资产？'),
        content: Text(
          '确认删除 "${asset.assetCode ?? asset.assetType.labelZh}"？\n\n'
          '资产将被软删除，历史估值事件仍保留但不再出现在列表中。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await ref.read(assetRepositoryProvider).softDelete(asset.id);
    if (!mounted) return;
    r.when(
      ok: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('资产已删除')));
        context.pop();
      },
      err: (e) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: ${errorToMessage(e)}'))),
    );
  }

  Future<void> _promptTransfer(Asset asset) async {
    final accountsAsync = ref.read(accountListProvider);
    final accounts = accountsAsync.value ?? const [];
    final targets = accounts
        .where((a) => a.id != asset.accountId && !a.isDeleted)
        .toList();
    if (targets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有其他可用账户')),
      );
      return;
    }

    final result = await showDialog<TransferResult?>(
      context: context,
      builder: (ctx) => TransferDialog(
        asset: asset,
        accounts: targets,
      ),
    );
    if (result == null || !mounted) return;

    final useCase = ref.read(transferAssetUseCaseProvider);
    final r = await useCase(TransferAssetRequest(
      assetId: asset.id,
      targetAccountId: result.targetAccountId,
      newQuantity: result.quantity,
    ));
    if (!mounted) return;
    r.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资产已划转')),
        );
        context.pop();
      },
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('划转失败: ${errorToMessage(e)}')),
      ),
    );
  }

  Future<void> _syncRange(BuildContext context, SyncWindow window) async {
    setState(() {
      _fetchingLatest = true;
      _fetchingHistory = true;
    });
    final useCase = ref.read(refreshAssetPriceUseCaseProvider);
    final range = window.rangeFrom(DateTime.now());

    Result<int, AppError>? histRes;
    Result<Asset, AppError>? latestRes;
    try {
      histRes = await useCase.refreshHistory(
        assetId: widget.assetId,
        from: range.from,
        to: range.to,
      );
      latestRes = await useCase.refreshLatest(widget.assetId);
    } catch (e) {
      latestRes ??= Err(UnknownError('sync error: $e'));
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLatest = false;
          _fetchingHistory = false;
        });
      }
    }

    if (!context.mounted) return;
    final errs = <String>[];
    if (histRes != null) {
      histRes.when(ok: (_) {}, err: (e) => errs.add('历史：${e.message}'));
    }
    latestRes.when(ok: (_) {}, err: (e) => errs.add('最新：${e.message}'));
    final wrote = histRes?.valueOrNull ?? 0;
    if (errs.any((e) => e.contains('yahoo blocked'))) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Yahoo Finance 不可用'),
            content: const Text(
              'Yahoo Finance 在中国大陆已被屏蔽（2021年11月起）。\n\n'
              '如需同步行情，请开启 VPN/代理后重试；\n'
              '或点击「手动输入价格」自行录入当前价。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('我知道了'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final msg = errs.isEmpty ? '已同步，补齐 $wrote 条历史点' : '同步出错：${errs.join('；')}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _promptUpdatePrice(BuildContext context) async {
    final asset = ref.read(assetByIdProvider(widget.assetId)).asData?.value;
    if (asset == null) return;
    final ctrl = TextEditingController(
      text: asset.currentPrice?.toString() ?? '',
    );
    final ok = await showDialog<Decimal>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更新价格 · ${asset.assetCode ?? asset.assetType.labelZh}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '当前价 (${asset.currency})'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final d = Decimal.tryParse(ctrl.text.trim());
              if (d != null && d >= Decimal.zero) Navigator.pop(ctx, d);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok == null) return;
    final r = await ref
        .read(valuateAssetUseCaseProvider)
        .call(assetId: asset.id, newPrice: ok);
    if (!context.mounted) return;
    r.when(
      ok: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('估值已更新'))),
      err: (e) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新失败: ${errorToMessage(e)}'))),
    );
  }

  List<_Point> _extractPoints(List<AssetPriceHistoryPoint> points) {
    return [for (final p in points) _Point(t: p.triggerTime, price: p.price)];
  }

  List<_Point> _filterByRange(List<_Point> all, int days) {
    if (days <= 0 || all.isEmpty) return all;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((p) => p.t.isAfter(cutoff)).toList();
  }

  _Coverage _coverage(List<_Point> all, int days) {
    if (all.isEmpty) return _Coverage.empty;
    if (days <= 0) return _Coverage.ok;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final earliest = all.first.t;
    if (earliest.isAfter(cutoff)) return _Coverage.insufficient;
    return _Coverage.ok;
  }
}

enum _Coverage { ok, insufficient, empty }

class _Point {
  const _Point({required this.t, required this.price});
  final DateTime t;
  final Decimal price;
}

// ──────────────────────────────────────────────────────────────
// Section card wrapper (consistent with account detail pattern)
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
// 1) Asset Hero
// ──────────────────────────────────────────────────────────────

class _AssetHero extends StatelessWidget {
  const _AssetHero({
    required this.asset,
    required this.valuedAsset,
    required this.valuationCurrency,
    required this.points,
  });
  final Asset asset;
  final ValuedAsset? valuedAsset;
  final String valuationCurrency;
  final List<_Point> points;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColors[asset.assetType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[asset.assetType] ?? Icons.show_chart;
    final currentPrice = asset.currentPrice;
    final title = asset.assetCode ?? asset.assetType.labelZh;

    // Calculate change from previous valuation point
    Decimal? changeAbs;
    Decimal? changePct;
    if (points.length >= 2 && currentPrice != null) {
      final prev = points[points.length - 2].price;
      final curr = currentPrice;
      changeAbs = curr - prev;
      if (prev != Decimal.zero) changePct = Money.percent(changeAbs, prev);
    }
    final isUp = changeAbs == null || changeAbs >= Decimal.zero;
    final changeColor = changeAbs == null
        ? GwpColors.textMuted
        : (isUp ? GwpColors.positive : GwpColors.negative);

    // Sparkline data from last 30 points
    final sparkData = points.length >= 2
        ? points
              .skip(max(0, points.length - 30))
              .map((p) => p.price.toDouble())
              .toList()
        : <double>[];

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
          colors: [typeColor.withValues(alpha: 0.18), GwpColors.surface1],
        ),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(GwpSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type badge + status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(typeIcon, size: 22, color: typeColor),
              ),
              const SizedBox(width: GwpSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_assetTypeLabel(asset.assetType)} · ${asset.currency}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GwpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GwpStatusBadge(
                label: _assetStatusLabel(asset.status),
                variant: _statusVariant(asset.status),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.lg),
          // Hero price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前价格',
                      style: TextStyle(
                        fontSize: 11,
                        color: GwpColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPrice == null
                          ? '—'
                          : heroFormat(currentPrice),
                      style: const TextStyle(
                        fontFamily: GwpTypo.monoFont,
                        fontFeatures: GwpTypo.tabularFigures,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    if (currentPrice != null)
                      Text(
                        asset.currency,
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
                GwpMiniChart(data: sparkData, width: 96, height: 40),
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
                  displayNumber(changeAbs, alwaysShowSign: true),
                  style: TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (changePct != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isUp ? GwpColors.positiveBg : GwpColors.negativeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayPercent(changePct, alwaysShowSign: true),
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
                  '需要更多估值点',
                  style: TextStyle(fontSize: 12, color: GwpColors.textMuted),
                ),
              const Spacer(),
              if (asset.valuationTime != null)
                Text(
                  _fmtDateTime(asset.valuationTime!),
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
                icon: Icons.inventory_2_outlined,
                label: '数量',
                value: asset.quantity.toString(),
              ),
              const SizedBox(width: GwpSpacing.sm),
              _HeroChip(
                icon: Icons.account_balance_wallet_outlined,
                label: '市值',
                value: valuedAsset?.valuedAmount == null
                    ? '—'
                    : compactValue(valuedAsset!.valuedAmount!.toDouble()),
              ),
              const SizedBox(width: GwpSpacing.sm),
              _HeroChip(
                icon: Icons.paid_outlined,
                label: '计价',
                value: valuationCurrency,
              ),
            ],
          ),
          if (valuedAsset?.valuedAmount != null) ...[
            const SizedBox(height: GwpSpacing.sm),
            Text(
              Money.format(
                valuedAsset!.valuedAmount!,
                currency: valuationCurrency,
              ),
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
            ),
          ],
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
                          color: GwpColors.actionPrimary.withValues(alpha: 0.4),
                          width: 0.5,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  r.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: r.$1 == current
                        ? FontWeight.w600
                        : FontWeight.w400,
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
    if (coverage == _Coverage.ok) return const SizedBox.shrink();
    final msg = coverage == _Coverage.empty
        ? '暂无估值数据，点击右上「同步」拉取'
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
  const _PriceChart({required this.points, required this.currency});
  final List<_Point> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return Center(
        child: Text(
          points.isEmpty ? '暂无估值数据' : '仅 1 个数据点，无法绘图',
          style: const TextStyle(fontSize: 13, color: GwpColors.textMuted),
        ),
      );
    }
    final values = points.map((p) => p.price.toDouble()).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    final isUp = values.last >= values.first;
    final lineColor = isUp ? GwpColors.positive : GwpColors.negative;

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
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
                            _fmtPrice(value),
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
                      interval: _xInterval(points.length),
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _shortDate(points[idx].t),
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
                    getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                      final idx = s.x.toInt().clamp(0, points.length - 1);
                      final p = points[idx];
                      return LineTooltipItem(
                        '${_fmtDate(p.t)}\n${_fmtPrice(p.price.toDouble())} $currency',
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
                      .map(
                        (_) => TouchedSpotIndicatorData(
                          FlLine(
                            color: lineColor.withValues(alpha: 0.4),
                            strokeWidth: 1,
                            dashArray: [3, 2],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                              radius: 3,
                              color: lineColor,
                              strokeWidth: 2,
                              strokeColor: GwpColors.surface1,
                            ),
                          ),
                        ),
                      )
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
                _fmtDate(points.first.t),
                style: const TextStyle(fontSize: 9, color: GwpColors.textMuted),
              ),
              Text(
                _fmtDate(points.last.t),
                style: const TextStyle(fontSize: 9, color: GwpColors.textMuted),
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

  String _shortDate(DateTime t) {
    final l = t.toLocal();
    return '${l.month}/${l.day}';
  }
}

// ──────────────────────────────────────────────────────────────
// Range stats (4 mini stat cards)
// ──────────────────────────────────────────────────────────────

class _RangeStats extends StatelessWidget {
  const _RangeStats({required this.points});
  final List<_Point> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final values = points.map((p) => p.price.toDouble()).toList();
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final first = values.first;
    final last = values.last;
    final changePct = first == 0 ? 0.0 : (last - first) / first * 100;
    final isUp = changePct >= 0;

    return Row(
      children: [
        _MiniStatCard(
          icon: Icons.arrow_upward_outlined,
          iconColor: GwpColors.positive,
          label: '区间高',
          value: _fmtPrice(high),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.arrow_downward_outlined,
          iconColor: GwpColors.negative,
          label: '区间低',
          value: _fmtPrice(low),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.trending_flat_outlined,
          iconColor: GwpColors.info,
          label: '均值',
          value: _fmtPrice(avg),
        ),
        const SizedBox(width: 6),
        _MiniStatCard(
          icon: Icons.trending_up_outlined,
          iconColor: isUp ? GwpColors.positive : GwpColors.negative,
          label: '涨跌',
          value: displayPercentDouble(changePct, alwaysShowSign: true),
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
              style: const TextStyle(fontSize: 9, color: GwpColors.textMuted),
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
// 3) Holding analysis (P&L)
// ──────────────────────────────────────────────────────────────

class _HoldingAnalysis extends StatelessWidget {
  const _HoldingAnalysis({
    required this.asset,
    required this.valuedAsset,
    required this.valuationCurrency,
  });
  final Asset asset;
  final ValuedAsset? valuedAsset;
  final String valuationCurrency;

  @override
  Widget build(BuildContext context) {
    final qty = asset.quantity;
    final cost = asset.costPrice;
    final cur = asset.currentPrice;
    final mv = valuedAsset?.valuedAmount;
    final totalCost = valuedAsset?.valuedCostBasis;
    Decimal? pnl;
    Decimal? pnlPct;
    if (totalCost != null && mv != null) {
      pnl = mv - totalCost;
      if (totalCost != Decimal.zero) pnlPct = Money.percent(pnl, totalCost);
    }
    final isUp = pnl == null || pnl >= Decimal.zero;
    final pnlColor = pnl == null
        ? GwpColors.textSecondary
        : (isUp ? GwpColors.positive : GwpColors.negative);

    String money(Decimal? d) =>
        d == null ? '—' : Money.format(d, currency: valuationCurrency);

    // PnL hero
    return Column(
      children: [
        // PnL hero row
        if (pnl != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GwpSpacing.md),
            decoration: BoxDecoration(
              color: isUp ? GwpColors.positiveBg : GwpColors.negativeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  '盈亏',
                  style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isUp ? '+' : ''}${money(pnl)}',
                  style: TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontFeatures: GwpTypo.tabularFigures,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: pnlColor,
                  ),
                ),
                if (pnlPct != null)
                  Text(
                    displayPercent(pnlPct, alwaysShowSign: true),
                    style: TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pnlColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: GwpSpacing.md),
        ],
        // Compare bar: total cost vs market value
        if (totalCost != null && mv != null) ...[
          _CompareBar(
            label1: '总成本',
            value1: totalCost.toDouble(),
            label2: '总市值 · $valuationCurrency',
            value2: mv.toDouble(),
            color1: GwpColors.textMuted,
            color2: isUp ? GwpColors.positive : GwpColors.negative,
          ),
          const SizedBox(height: GwpSpacing.md),
        ],
        // Detail grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final columns = isNarrow ? 2 : 3;
            final itemWidth =
                (constraints.maxWidth - GwpSpacing.sm * (columns - 1)) /
                columns;

            return Wrap(
              spacing: GwpSpacing.sm,
              runSpacing: GwpSpacing.sm,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(label: '持仓数量', value: qty.toString()),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(label: '成本价', value: cost?.toString() ?? '—'),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(label: '现价', value: cur?.toString() ?? '—'),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(
                    label: '总市值',
                    value: money(mv),
                    emphasize: true,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(label: '总成本', value: money(totalCost)),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCell(label: '原币', value: asset.currency),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
    required this.color1,
    required this.color2,
  });
  final String label1;
  final double value1;
  final String label2;
  final double value2;
  final Color color1;
  final Color color2;

  @override
  Widget build(BuildContext context) {
    final maxVal = max(value1, value2);
    final frac1 = maxVal > 0 ? (value1 / maxVal).clamp(0.0, 1.0) : 0.0;
    final frac2 = maxVal > 0 ? (value2 / maxVal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        _barRow(label1, value1, frac1, color1),
        const SizedBox(height: 6),
        _barRow(label2, value2, frac2, color2),
      ],
    );
  }

  Widget _barRow(String label, double value, double frac, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 14,
              child: LinearProgressIndicator(
                value: frac,
                backgroundColor: GwpColors.surface3,
                valueColor: AlwaysStoppedAnimation(
                  color.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          compactValue(value),
          style: const TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontFeatures: GwpTypo.tabularFigures,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: GwpColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: emphasize ? 14 : 12,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              color: GwpColors.textPrimary,
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 4) Linked account card
// ──────────────────────────────────────────────────────────────

class _AccountLinkCard extends StatelessWidget {
  const _AccountLinkCard({
    required this.asset,
    required this.account,
    required this.accountRegionLabel,
  });
  final Asset asset;
  final Account? account;
  final String? accountRegionLabel;

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return Container(
        padding: const EdgeInsets.all(GwpSpacing.md),
        decoration: BoxDecoration(
          color: GwpColors.surface2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: GwpColors.textMuted,
            ),
            const SizedBox(width: GwpSpacing.sm),
            Expanded(
              child: Text(
                '关联账户不可用 · ${asset.accountId.substring(0, min(8, asset.accountId.length))}...',
                style: const TextStyle(
                  fontSize: 12,
                  color: GwpColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final a = account!;
    return Material(
      color: GwpColors.surface2.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/accounts/${a.id}'),
        child: Padding(
          padding: const EdgeInsets.all(GwpSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GwpColors.actionPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance,
                  size: 18,
                  color: GwpColors.actionPrimary,
                ),
              ),
              const SizedBox(width: GwpSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.institutionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.accountType.labelZh} · ${accountRegionLabel ?? a.sovereigntyRegion}'
                      '${a.accountNo != null ? ' · ${a.accountNo}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: GwpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: GwpColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 5) Basic info
// ──────────────────────────────────────────────────────────────

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('类型', _assetTypeLabel(asset.assetType)),
      ('状态', _assetStatusLabel(asset.status)),
      ('币种', asset.currency),
      if (asset.assetCode != null) ('代码', asset.assetCode!),
      ('创建时间', _fmtDateTime(asset.createdAt)),
      ('更新时间', _fmtDateTime(asset.updatedAt)),
      ('资产ID', asset.id),
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
              style: const TextStyle(fontSize: 12, color: GwpColors.textMuted),
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
// 6) Valuation history timeline
// ──────────────────────────────────────────────────────────────

class _HistoryTimeline extends StatefulWidget {
  const _HistoryTimeline({required this.points, required this.currency});
  final List<_Point> points;
  final String currency;

  @override
  State<_HistoryTimeline> createState() => _HistoryTimelineState();
}

class _HistoryTimelineState extends State<_HistoryTimeline> {
  static const _previewLimit = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final recent = widget.points.reversed.toList();
    final visible = _showAll ? recent : recent.take(_previewLimit).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++)
          _HistoryRow(
            point: visible[i],
            prev: i < visible.length - 1 ? visible[i + 1] : null,
            currency: widget.currency,
            isFirst: i == 0,
            isLast: i == visible.length - 1 && _showAll,
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
    required this.point,
    required this.prev,
    required this.currency,
    required this.isFirst,
    required this.isLast,
  });
  final _Point point;
  final _Point? prev;
  final String currency;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    double? changePct;
    if (prev != null) {
      final p = prev!.price.toDouble();
      if (p != 0) {
        changePct = (point.price.toDouble() - p) / p * 100;
      }
    }
    final isUp = (changePct ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Timeline dot
          Column(
            children: [
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
            ],
          ),
          const SizedBox(width: GwpSpacing.sm),
          // Date
          SizedBox(
            width: 80,
            child: Text(
              _fmtDate(point.t),
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 11,
                color: GwpColors.textSecondary,
              ),
            ),
          ),
          // Price
          Expanded(
            child: Text(
              '${point.price} $currency',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isUp ? GwpColors.positiveBg : GwpColors.negativeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayPercentDouble(changePct, alwaysShowSign: true),
                      style: TextStyle(
                        fontFamily: GwpTypo.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUp ? GwpColors.positive : GwpColors.negative,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
