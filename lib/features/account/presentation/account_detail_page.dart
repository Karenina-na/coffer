import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/format_utils.dart';
import '../../../core/ui/gwp_donut_chart.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../../../domain/usecases/aggregate_account_value.dart';
import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/usecases/refresh_asset_price.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_by_account_providers.dart';
import '../../card/presentation/card_detail_sheet.dart';
import '../../channel/presentation/channel_providers.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../exchange_rate/presentation/rate_sparkline.dart';
import 'account_providers.dart';

// ──────────────────────────────────────────────────────────────
// Account type → icon / color
// ──────────────────────────────────────────────────────────────

const _typeIcons = <AccountType, IconData>{
  AccountType.bank: Icons.account_balance,
  AccountType.broker: Icons.show_chart,
  AccountType.insurance: Icons.shield_outlined,
  AccountType.payment: Icons.account_balance_wallet,
  AccountType.custody: Icons.lock_outlined,
  AccountType.cryptoExchange: Icons.currency_bitcoin,
  AccountType.cryptoWallet: Icons.wallet,
};

const _typeColors = <AccountType, Color>{
  AccountType.bank: Color(0xFF64748B),
  AccountType.broker: Color(0xFF22C55E),
  AccountType.insurance: Color(0xFFA78BFA),
  AccountType.payment: Color(0xFFF59E0B),
  AccountType.custody: Color(0xFF94A3B8),
  AccountType.cryptoExchange: Color(0xFFFB923C),
  AccountType.cryptoWallet: Color(0xFFEC4899),
};

// ──────────────────────────────────────────────────────────────
// Protocol colors (reused from transfer simulate)
// ──────────────────────────────────────────────────────────────

const _protocolColors = <String, Color>{
  'SWIFT': Color(0xFF64748B),
  'ACH': Color(0xFF22C55E),
  'SEPA': Color(0xFF38BDF8),
  'CNAPS': Color(0xFFEF4444),
  'RTGS': Color(0xFFA78BFA),
  'FPS': Color(0xFFF59E0B),
  'ONCHAIN': Color(0xFFEC4899),
  'INTERNAL': Color(0xFF94A3B8),
};

// ──────────────────────────────────────────────────────────────
// Allocation palette
// ──────────────────────────────────────────────────────────────

const _allocationPalette = [
  Color(0xFF64748B),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFFA78BFA),
  Color(0xFF38BDF8),
  Color(0xFFFB923C),
  Color(0xFF14B8A6),
  Color(0xFF6366F1),
  Color(0xFFEF4444),
];

Color _sliceColor(int i) => _allocationPalette[i % _allocationPalette.length];

const _assetTypeColors = <String, Color>{
  'stock': Color(0xFF64748B),
  'equity': Color(0xFF6366F1),
  'fund': Color(0xFF22C55E),
  'bond': Color(0xFFF59E0B),
  'cd': Color(0xFFA78BFA),
  'crypto': Color(0xFFEC4899),
  'fxAsset': Color(0xFF38BDF8),
  'option': Color(0xFFFF6B6B),
  'future': Color(0xFF845EC2),
  'warrant': Color(0xFFD65DB1),
  'policy': Color(0xFF00C9A7),
  'perpetual': Color(0xFFC34A36),
  'contract': Color(0xFF008F7A),
  'preciousMetal': Color(0xFFDAA520),
};

// ──────────────────────────────────────────────────────────────
// Value formatters
// ──────────────────────────────────────────────────────────────
// heroFormat / compactValue 已提取到 lib/core/ui/format_utils.dart

// ──────────────────────────────────────────────────────────────
// Main page
// ──────────────────────────────────────────────────────────────

class AccountDetailPage extends ConsumerStatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage> {
  String _baseCurrency = 'CNY';
  Future<AccountAggregate?>? _aggFuture;
  List<Asset> _lastAssets = const [];
  bool _syncing = false;

  Future<AccountAggregate?> _aggregate(List<Asset> assets) async {
    final r = await ref
        .read(aggregateAccountValueUseCaseProvider)
        .call(assets: assets, baseCurrency: _baseCurrency);
    return r.valueOrNull;
  }

  void _triggerAggregate(List<Asset> assets) {
    final sameLen = assets.length == _lastAssets.length;
    final sameSig = sameLen &&
        () {
          for (var i = 0; i < assets.length; i++) {
            if (assets[i].id != _lastAssets[i].id ||
                assets[i].marketValue != _lastAssets[i].marketValue ||
                assets[i].currency != _lastAssets[i].currency) {
              return false;
            }
          }
          return true;
        }();
    if (_aggFuture == null || !sameSig) {
      _lastAssets = assets;
      _aggFuture = _aggregate(assets);
    }
  }

  void _onMoreAction(String action, List<Account>? list) {
    final account =
        list?.where((a) => a.id == widget.accountId).firstOrNull;
    if (account == null) return;
    switch (action) {
      case 'edit':
        context.push('/accounts/${account.id}/edit');
      case 'delete':
        _confirmDelete(account);
    }
  }

  Future<void> _confirmDelete(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账户？'),
        content: Text(
          '确认删除 "${account.institutionName}"？\n\n'
          '账户将被软删除，关联资产 / 卡片仍保留历史记录，但不会再出现在列表中。',
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
    final r =
        await ref.read(accountRepositoryProvider).softDelete(account.id);
    if (!mounted) return;
    r.when(
      ok: (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('账户已删除')));
        context.pop();
      },
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${errorToMessage(e)}')),
      ),
    );
  }

  Future<void> _syncAllPrices(
      BuildContext context, List<Asset> assets, SyncMode mode) async {
    if (assets.isEmpty || _syncing) return;
    setState(() => _syncing = true);
    final useCase = ref.read(refreshAssetPriceUseCaseProvider);
    final ids = assets.map((a) => a.id).toList();

    Result<RefreshAssetsResult, AppError>? r;
    try {
      r = await useCase.refreshAll(
        assetIds: ids,
        mode: mode,
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
          _aggFuture = null;
        });
      }
    }

    if (!context.mounted) return;

    // Yahoo Finance 在中国大陆被屏蔽时弹窗提示
    if (r.isErr && (r.errorOrNull?.message.contains('yahoo blocked') ?? false)) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Yahoo Finance 不可用'),
          content: const Text(
            'Yahoo Finance 在中国大陆已被屏蔽（2021年11月起）。\n\n'
            '如需同步行情，请开启 VPN/代理后重试；\n'
            '或前往各资产详情页手动输入价格。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('我知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final failures = <String>[];
    final label = mode == SyncMode.incremental ? '增量' : '全量';
    final msg = r.when(
      ok: (res) {
        failures.addAll(res.failed.entries.map((e) => '${e.key}: ${e.value}'));
        return res.failed.isEmpty
            ? '$label同步成功 ${res.success.length} / ${assets.length} 条资产'
            : '$label同步 ${res.success.length} / ${assets.length}，失败 ${res.failed.length} 条';
      },
      err: (e) => '同步失败：${e.message}',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: failures.isEmpty
            ? null
            : SnackBarAction(
                label: '详情',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('同步失败'),
                      content: SingleChildScrollView(
                        child: Text(failures.join('\n')),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListProvider);
    final assetsAsync = ref.watch(assetsByAccountProvider(widget.accountId));
    final cardsAsync = ref.watch(cardsByAccountProvider(widget.accountId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('账户详情'),
        actions: [
          assetsAsync.maybeWhen(
            data: (assets) => PopupMenuButton<SyncMode>(
              tooltip: '同步资产价格',
              enabled: !(_syncing || assets.isEmpty),
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GwpColors.actionPrimary,
                      ),
                    )
                  : const Icon(Icons.sync),
              onSelected: (mode) => _syncAllPrices(context, assets, mode),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: SyncMode.incremental,
                  child: ListTile(
                    leading: Icon(Icons.update),
                    title: Text('增量同步（仅最新价）'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: SyncMode.full,
                  child: ListTile(
                    leading: Icon(Icons.history),
                    title: Text('全量同步（历史+最新）'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            tooltip: '基准币种',
            initialValue: _baseCurrency,
            onSelected: (v) => setState(() {
              _baseCurrency = v;
              _aggFuture = null;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'CNY', child: Text('CNY')),
              PopupMenuItem(value: 'USD', child: Text('USD')),
              PopupMenuItem(value: 'HKD', child: Text('HKD')),
              PopupMenuItem(value: 'SGD', child: Text('SGD')),
              PopupMenuItem(value: 'EUR', child: Text('EUR')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(_baseCurrency)),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '更多操作',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => _onMoreAction(v, accounts.value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('编辑'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('删除', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: accounts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(accountListProvider),
        ),
        data: (list) {
          final account =
              list.where((a) => a.id == widget.accountId).firstOrNull;
          if (account == null) {
            return const GwpEmptyState(
              icon: Icons.account_balance_outlined,
              title: '账户不存在或已删除',
              subtitle: '该账户可能已被移除',
            );
          }
          return assetsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: GwpColors.actionPrimary),
            ),
            error: (e, _) => GwpEmptyState.error(
              message: '加载资产失败: ${errorToMessage(e)}',
              onRetry: () => ref.invalidate(
                assetsByAccountProvider(widget.accountId),
              ),
            ),
            data: (assets) {
              _triggerAggregate(assets);
              return _Body(
                account: account,
                assets: assets,
                cardsAsync: cardsAsync,
                aggFuture: _aggFuture,
                baseCurrency: _baseCurrency,
                accountId: widget.accountId,
              );
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Body layout
// ──────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.account,
    required this.assets,
    required this.cardsAsync,
    required this.aggFuture,
    required this.baseCurrency,
    required this.accountId,
  });

  final Account account;
  final List<Asset> assets;
  final AsyncValue<List<BankCard>> cardsAsync;
  final Future<AccountAggregate?>? aggFuture;
  final String baseCurrency;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.md,
      ),
      children: [
        _AccountHero(
          account: account,
          assets: assets,
          cardsAsync: cardsAsync,
          aggFuture: aggFuture,
          baseCurrency: baseCurrency,
        ),
        const SizedBox(height: GwpSpacing.base),
        if (assets.isNotEmpty) ...[
          _AssetComposition(assets: assets),
          const SizedBox(height: GwpSpacing.base),
          _CostBasisSection(assets: assets, baseCurrency: baseCurrency),
          const SizedBox(height: GwpSpacing.base),
          _NetWorthTrendSection(accountId: accountId),
          const SizedBox(height: GwpSpacing.base),
        ],
        _AssetListSection(assets: assets),
        const SizedBox(height: GwpSpacing.base),
        _CardGallerySection(
          cardsAsync: cardsAsync,
          account: account,
        ),
        const SizedBox(height: GwpSpacing.base),
        _ChannelNetworkSection(accountId: accountId),
        const SizedBox(height: GwpSpacing.xxl),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §1  Account Hero (identity + value + stats)
// ──────────────────────────────────────────────────────────────

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.account,
    required this.assets,
    required this.cardsAsync,
    required this.aggFuture,
    required this.baseCurrency,
  });

  final Account account;
  final List<Asset> assets;
  final AsyncValue<List<BankCard>> cardsAsync;
  final Future<AccountAggregate?>? aggFuture;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColors[account.accountType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[account.accountType] ?? Icons.account_balance;
    final cardCount = cardsAsync.value?.length ?? 0;
    final currencies = assets.map((a) => a.currency).toSet();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.15),
            GwpColors.surface1,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GwpColors.borderStrong, width: 0.5),
      ),
      padding: const EdgeInsets.all(GwpSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: icon + name + status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, size: 22, color: typeColor),
              ),
              const SizedBox(width: GwpSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.institutionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GwpColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                       '${account.accountType.labelZh} · ${account.sovereigntyRegion}'
                      '${account.accountNo != null ? ' · ${account.accountNo}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GwpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GwpStatusBadge(
                 label: account.status.labelZh,
                variant: _statusVariant(account.status),
              ),
            ],
          ),
          if (account.openedAt != null) ...[
            const SizedBox(height: GwpSpacing.xs),
            Text(
              '开户 ${_formatDate(account.openedAt!)}',
              style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
            ),
          ],
          const SizedBox(height: GwpSpacing.lg),
          // Total value
          FutureBuilder<AccountAggregate?>(
            future: aggFuture,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GwpColors.actionPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '正在聚合市值…',
                      style: TextStyle(
                        fontSize: 12,
                        color: GwpColors.textMuted,
                      ),
                    ),
                  ],
                );
              }
              final agg = snap.data;
              if (agg == null) {
                return const Text(
                  '聚合失败',
                  style: TextStyle(fontSize: 14, color: GwpColors.negative),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heroFormat(agg.total),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontFeatures: GwpTypo.tabularFigures,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: GwpColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '总市值 · ${agg.baseCurrency}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: GwpColors.textMuted,
                        ),
                      ),
                      if (agg.missingRates.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${agg.missingRates.length} 项缺汇率',
                          style: const TextStyle(
                            fontSize: 10,
                            color: GwpColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: GwpSpacing.lg),
          // KPI chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniKpi(
                icon: Icons.pie_chart_outline,
                value: '${assets.length}',
                label: '资产',
              ),
              _MiniKpi(
                icon: Icons.credit_card_outlined,
                value: '$cardCount',
                label: '卡片',
              ),
              _MiniKpi(
                icon: Icons.currency_exchange,
                value: '${currencies.length}',
                label: '币种',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static StatusVariant _statusVariant(AccountStatus s) {
    return switch (s) {
      AccountStatus.active => StatusVariant.positive,
      AccountStatus.inactive => StatusVariant.warning,
      AccountStatus.dormant => StatusVariant.muted,
      AccountStatus.closed => StatusVariant.negative,
    };
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: GwpColors.actionPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: GwpColors.actionPrimary),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GwpColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §2  Asset Composition (donut + currency breakdown)
// ──────────────────────────────────────────────────────────────

class _AssetComposition extends StatelessWidget {
  const _AssetComposition({required this.assets});
  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    // Type distribution
    final typeTotals = <String, double>{};
    final currencyTotals = <String, double>{};
    for (final a in assets) {
      final mv = a.marketValue?.toDouble() ?? 0;
      if (mv <= 0) continue;
      typeTotals.update(a.assetType.name, (v) => v + mv, ifAbsent: () => mv);
      currencyTotals.update(a.currency, (v) => v + mv, ifAbsent: () => mv);
    }

    final segments = typeTotals.entries
        .where((e) => e.value > 0)
        .map((e) => ChartSegment(
              label: e.key,
              value: e.value,
              color: _assetTypeColors[e.key] ?? GwpColors.textMuted,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final currencyEntries = currencyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currTotal =
        currencyEntries.fold<double>(0, (s, e) => s + e.value);

    return _SectionCard(
      icon: Icons.donut_large_outlined,
      iconColor: GwpColors.actionPrimary,
      title: '资产构成',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donut + legend
          if (segments.isNotEmpty) ...[
            Row(
              children: [
                GwpDonutChart(
                  segments: segments,
                  size: 110,
                  strokeWidth: 18,
                  centerLabel: '${assets.length}',
                  centerSubLabel: '项资产',
                ),
                const SizedBox(width: GwpSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < segments.length && i < 6; i++)
                        _TypeLegendRow(segment: segments[i]),
                      if (segments.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${segments.length - 6} 类型',
                            style: const TextStyle(
                              fontSize: 10,
                              color: GwpColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          // Currency breakdown
          if (currencyEntries.isNotEmpty) ...[
            const SizedBox(height: GwpSpacing.lg),
            const _SubLabel('币种分布'),
            const SizedBox(height: GwpSpacing.sm),
            for (var i = 0; i < currencyEntries.length; i++) ...[
              _CurrencyRow(
                currency: currencyEntries[i].key,
                value: currencyEntries[i].value,
                total: currTotal,
                index: i,
              ),
              if (i < currencyEntries.length - 1)
                const SizedBox(height: GwpSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}

class _TypeLegendRow extends StatelessWidget {
  const _TypeLegendRow({required this.segment});
  final ChartSegment segment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: segment.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              segment.label,
              style: const TextStyle(
                fontSize: 11,
                color: GwpColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            compactValue(segment.value),
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 10,
              color: GwpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.value,
    required this.total,
    required this.index,
  });

  final String currency;
  final double value;
  final double total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    final color = _sliceColor(index);

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            currency,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                backgroundColor: GwpColors.surface3,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontSize: 10,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 44,
          child: Text(
            compactValue(value),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: GwpColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §3  Cost Basis / P&L Analysis
// ──────────────────────────────────────────────────────────────

class _CostBasisSection extends StatelessWidget {
  const _CostBasisSection({
    required this.assets,
    required this.baseCurrency,
  });

  final List<Asset> assets;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    // Only show if at least one asset has costPrice
    Decimal totalCost = Decimal.zero;
    Decimal totalMarket = Decimal.zero;
    int withCost = 0;

    for (final a in assets) {
      final mv = a.marketValue ?? Decimal.zero;
      final cp = a.costPrice;
      if (mv > Decimal.zero) totalMarket += mv;
      if (cp != null && cp > Decimal.zero && a.quantity > Decimal.zero) {
        totalCost += cp * a.quantity;
        withCost++;
      }
    }

    if (withCost == 0) return const SizedBox.shrink();

    final pnl = totalMarket - totalCost;
    final pnlPct = totalCost > Decimal.zero
        ? Money.percent(pnl, totalCost)
        : Decimal.zero;
    final isProfit = pnl >= Decimal.zero;
    final pnlColor = isProfit ? GwpColors.positive : GwpColors.negative;

    return _SectionCard(
      icon: Icons.trending_up_outlined,
      iconColor: pnlColor,
      title: '成本与收益',
      child: Column(
        children: [
          // P&L hero number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isProfit ? '+' : ''}${heroFormat(pnl)}',
                style: TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: pnlColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isProfit ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: pnlColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          // Cost vs Market bar
          _CompareBar(
            label1: '总成本',
            value1: totalCost.toDouble(),
            label2: '总市值',
            value2: totalMarket.toDouble(),
            color1: GwpColors.textMuted,
            color2: pnlColor,
          ),
          const SizedBox(height: GwpSpacing.sm),
          // Coverage note
          Text(
            '$withCost / ${assets.length} 项资产有成本价',
            style: const TextStyle(
              fontSize: 10,
              color: GwpColors.textMuted,
            ),
          ),
        ],
      ),
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
              fontSize: 11,
              color: GwpColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 16,
              child: LinearProgressIndicator(
                value: frac,
                backgroundColor: GwpColors.surface3,
                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
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

// ──────────────────────────────────────────────────────────────
// §3.5  Net Worth Trend (account-scoped)
// ──────────────────────────────────────────────────────────────

class _NetWorthTrendSection extends ConsumerStatefulWidget {
  const _NetWorthTrendSection({required this.accountId});
  final String accountId;

  @override
  ConsumerState<_NetWorthTrendSection> createState() =>
      _NetWorthTrendSectionState();
}

class _NetWorthTrendSectionState extends ConsumerState<_NetWorthTrendSection> {
  int _range = 30; // 0 = ALL

  @override
  Widget build(BuildContext context) {
    final deltaAsync = ref.watch(
      accountTrendDeltaProvider((widget.accountId, _range)),
    );

    return _SectionCard(
      icon: Icons.show_chart,
      iconColor: GwpColors.actionPrimary,
      title: '净值趋势',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _TrendRangeChips(
              selected: _range,
              onSelected: (v) => setState(() => _range = v),
            ),
          ),
          const SizedBox(height: GwpSpacing.sm),
          deltaAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: GwpColors.actionPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox(
              height: 200,
              child: Center(
                child: Icon(Icons.error_outline, color: GwpColors.textMuted),
              ),
            ),
            data: (delta) {
              if (!delta.hasEnoughData) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      '数据不足，估值更新后将显示趋势',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: GwpColors.textMuted,
                          ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrendStats(delta: delta),
                  const SizedBox(height: GwpSpacing.md),
                  SizedBox(height: 160, child: _AccountTrendChart(delta: delta)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendRangeChips extends StatelessWidget {
  const _TrendRangeChips({required this.selected, required this.onSelected});
  final int selected;
  final void Function(int days) onSelected;

  static const _options = [
    (7, '7D'),
    (30, '1M'),
    (90, '3M'),
    (365, '1Y'),
    (0, 'ALL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (days, label) in _options)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () => onSelected(days),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected == days
                      ? GwpColors.actionPrimary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selected == days ? FontWeight.w700 : FontWeight.w500,
                    color: selected == days
                        ? GwpColors.actionPrimary
                        : GwpColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendStats extends StatelessWidget {
  const _TrendStats({required this.delta});
  final TrendDelta delta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TrendKv(label: '期初', value: compactValue(delta.startValue))),
        Expanded(
          child: _TrendKv(
            label: '期末',
            value: compactValue(delta.endValue),
            emphasize: true,
          ),
        ),
        Expanded(
          child: _TrendKv(
            label: delta.isUp ? '区间最高' : '区间最低',
            value: compactValue(delta.isUp ? delta.maxValue : delta.minValue),
            color: delta.isUp ? GwpColors.positive : GwpColors.negative,
          ),
        ),
        Expanded(
          child: _TrendKv(
            label: '区间变动',
            value:
                '${delta.isUp ? '+' : ''}${(delta.deltaPct * 100).toStringAsFixed(2)}%',
            color: delta.isUp ? GwpColors.positive : GwpColors.negative,
          ),
        ),
      ],
    );
  }
}

class _TrendKv extends StatelessWidget {
  const _TrendKv({
    required this.label,
    required this.value,
    this.color,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontFeatures: GwpTypo.tabularFigures,
            fontSize: emphasize ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: color ?? GwpColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AccountTrendChart extends StatelessWidget {
  const _AccountTrendChart({required this.delta});
  final TrendDelta delta;

  @override
  Widget build(BuildContext context) {
    final points = delta.points;
    final isUp = delta.isUp;
    final lineColor = isUp ? GwpColors.positive : GwpColors.negative;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final range = delta.maxValue - delta.minValue;
    final paddedMin = delta.minValue - range * 0.1;
    final paddedMax = delta.maxValue + range * 0.1;
    final refValue = delta.startValue;

    return LineChart(
      LineChartData(
        minY: range > 0 ? paddedMin : delta.minValue - 1,
        maxY: range > 0 ? paddedMax : delta.maxValue + 1,
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
                    compactValue(value),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 9,
                      color: GwpColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: refValue,
              color: GwpColors.textMuted.withValues(alpha: 0.4),
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => GwpColors.surface3,
            tooltipRoundedRadius: 6,
            getTooltipItems: (spots) => spots.map((s) {
              final p = points[s.x.toInt()];
              final dateStr =
                  '${p.date.month.toString().padLeft(2, '0')}/${p.date.day.toString().padLeft(2, '0')}';
              return LineTooltipItem(
                '$dateStr\n${compactValue(p.value)}',
                const TextStyle(
                  color: GwpColors.textPrimary,
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
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
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §4  Asset List (with sparklines)
// ──────────────────────────────────────────────────────────────

class _AssetListSection extends StatefulWidget {
  const _AssetListSection({required this.assets});
  final List<Asset> assets;

  @override
  State<_AssetListSection> createState() => _AssetListSectionState();
}

class _AssetListSectionState extends State<_AssetListSection> {
  static const _previewLimit = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final assets = widget.assets;
    final visible = _showAll ? assets : assets.take(_previewLimit).toList();

    return _SectionCard(
      icon: Icons.view_list_outlined,
      iconColor: GwpColors.info,
      title: '资产明细 (${assets.length})',
      child: assets.isEmpty
          ? const _EmptyHint('账户下暂无资产')
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _AssetRow(asset: visible[i]),
                  if (i < visible.length - 1)
                    const Divider(height: 1, color: GwpColors.border),
                ],
                if (!_showAll && assets.length > _previewLimit)
                  _ShowMoreBtn(
                    remaining: assets.length - _previewLimit,
                    onPressed: () => setState(() => _showAll = true),
                  ),
              ],
            ),
    );
  }
}

class _AssetRow extends ConsumerWidget {
  const _AssetRow({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(assetValuationHistoryProvider(asset.id));
    final rawPoints = historyAsync.maybeWhen(
      data: (p) => p,
      orElse: () => const <AssetPriceHistoryPoint>[],
    );
    Decimal? changePct;
    if (rawPoints.length >= 2) {
      final a = rawPoints.first.price;
      final b = rawPoints.last.price;
      if (a != Decimal.zero) changePct = Money.percent(b - a, a);
    }
    final isUp = changePct == null || changePct >= Decimal.zero;
    final changeColor = changePct == null
        ? GwpColors.textMuted
        : (isUp ? GwpColors.positive : GwpColors.negative);
    final mv = asset.marketValue;
    final typeColor =
        _assetTypeColors[asset.assetType.name] ?? GwpColors.actionPrimary;

    return InkWell(
      onTap: () => context.push('/assets/${asset.id}'),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.xs,
          vertical: GwpSpacing.sm,
        ),
        child: Row(
          children: [
            // Type dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: GwpSpacing.sm),
            // Left: code + type · qty
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     asset.assetCode ?? asset.assetType.labelZh,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                     '${asset.assetType.labelZh} · ${asset.quantity}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: GwpColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Center: sparkline
            Expanded(
              flex: 3,
              child: Center(
                child: RateSparkline(
                  points: rawPoints.map((p) => p.price.toDouble()).toList(),
                  isUp: isUp,
                ),
              ),
            ),
            // Right: market value + change
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mv == null
                        ? '—'
                        : Money.format(mv, currency: asset.currency),
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontFeatures: GwpTypo.tabularFigures,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    changePct == null
                        ? asset.currency
                        : '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: changeColor,
                    ),
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
// §5  Card Gallery
// ──────────────────────────────────────────────────────────────

class _CardGallerySection extends StatelessWidget {
  const _CardGallerySection({
    required this.cardsAsync,
    required this.account,
  });

  final AsyncValue<List<BankCard>> cardsAsync;
  final Account account;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.credit_card_outlined,
      iconColor: const Color(0xFFF59E0B),
      title: '银行卡',
      child: cardsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text(
          '加载卡片失败: ${errorToMessage(e)}',
          style: const TextStyle(color: GwpColors.negative, fontSize: 12),
        ),
        data: (cards) {
          if (cards.isEmpty) return const _EmptyHint('账户下暂无卡片');
          return Wrap(
            spacing: GwpSpacing.sm,
            runSpacing: GwpSpacing.sm,
            children: [for (final c in cards) _VisualCard(card: c, account: account)],
          );
        },
      ),
    );
  }
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({required this.card, required this.account});
  final BankCard card;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final isCredit = card.cardType.code == 'CREDIT';
    final orgColor = _orgColor(card.cardOrganization);

    // Credit utilization
    double? utilization;
    if (isCredit &&
        card.creditLimit != null &&
        card.availableCredit != null &&
        card.creditLimit! > Decimal.zero) {
      final used = card.creditLimit! - card.availableCredit!;
      utilization = (used / card.creditLimit!).toDouble().clamp(0, 1);
    }

    return GestureDetector(
      onTap: () => CardDetailSheet.show(context, card: card, account: account),
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(GwpSpacing.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              orgColor.withValues(alpha: 0.15),
              GwpColors.surface2,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GwpColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: org + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardOrganization,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: orgColor,
                  ),
                ),
                GwpStatusBadge(
                   label: card.status.labelZh,
                  variant: _cardStatusVariant(card.status),
                ),
              ],
            ),
            const SizedBox(height: GwpSpacing.sm),
            // Masked number
            Text(
              card.cardNoMasked,
              style: const TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontFeatures: GwpTypo.tabularFigures,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Type + expiry
            Text(
               '${card.cardType.labelZh} · ${card.expireMonth.toString().padLeft(2, '0')}/${card.expireYear}',
              style: const TextStyle(
                fontSize: 10,
                color: GwpColors.textSecondary,
              ),
            ),
            // Credit utilization bar
            if (utilization != null) ...[
              const SizedBox(height: GwpSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: utilization,
                    backgroundColor: GwpColors.surface3,
                    valueColor: AlwaysStoppedAnimation(
                      utilization > 0.8
                          ? GwpColors.negative
                          : utilization > 0.5
                              ? GwpColors.warning
                              : GwpColors.positive,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '额度使用 ${(utilization * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 9,
                  color: GwpColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _orgColor(String org) {
    final lower = org.toLowerCase();
    if (lower.contains('visa')) return const Color(0xFF1A1F71);
    if (lower.contains('master')) return const Color(0xFFEB001B);
    if (lower.contains('unionpay') || lower.contains('银联')) {
      return const Color(0xFFE21836);
    }
    if (lower.contains('amex') || lower.contains('american')) {
      return const Color(0xFF006FCF);
    }
    if (lower.contains('jcb')) return const Color(0xFF0E4C96);
    return GwpColors.actionPrimary;
  }

  static StatusVariant _cardStatusVariant(dynamic s) {
    final code = s.code as String;
    return switch (code) {
      'ACTIVE' => StatusVariant.positive,
      'LOCKED' => StatusVariant.warning,
      'EXPIRED' => StatusVariant.muted,
      'CLOSED' => StatusVariant.negative,
      _ => StatusVariant.neutral,
    };
  }
}

// ──────────────────────────────────────────────────────────────
// §6  Channel Network
// ──────────────────────────────────────────────────────────────

class _ChannelNetworkSection extends ConsumerWidget {
  const _ChannelNetworkSection({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync =
        ref.watch(accountChannelsByAccountProvider(accountId));
    final channelsAsync = ref.watch(channelListProvider);

    return _SectionCard(
      icon: Icons.swap_horiz_outlined,
      iconColor: GwpColors.info,
      title: '转账通道',
      child: linksAsync.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text(
          '加载失败: ${errorToMessage(e)}',
          style: const TextStyle(color: GwpColors.negative, fontSize: 12),
        ),
        data: (links) => channelsAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text(
            '加载通道失败: ${errorToMessage(e)}',
            style: const TextStyle(color: GwpColors.negative, fontSize: 12),
          ),
          data: (channels) {
            final byId = {for (final c in channels) c.id: c};
            final attached = [
              for (final l in links)
                if (byId[l.channelId] != null) byId[l.channelId]!,
            ];
            final available = channels
                .where((c) => !links.any((l) => l.channelId == c.id))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attached.isEmpty)
                  const _EmptyHint('该账户尚未接入任何通道')
                else
                  for (var i = 0; i < attached.length; i++) ...[
                    _ChannelCard(
                      channel: attached[i],
                      accountId: accountId,
                    ),
                    if (i < attached.length - 1)
                      const SizedBox(height: GwpSpacing.sm),
                  ],
                const SizedBox(height: GwpSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: available.isEmpty
                        ? null
                        : () => _pickAndLink(context, ref, available),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('添加通道', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickAndLink(
    BuildContext context,
    WidgetRef ref,
    List<Channel> available,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in available)
              ListTile(
                leading: Icon(
                  Icons.swap_horiz,
                  color:
                      _protocolColors[c.transferProtocol] ?? GwpColors.textMuted,
                ),
                title: Text(c.name),
                subtitle: Text(c.transferProtocol),
                onTap: () => Navigator.of(ctx).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final r = await ref
        .read(linkAccountChannelUseCaseProvider)
        .link(accountId: accountId, channelId: picked);
    if (!context.mounted) return;
    r.when(
      ok: (_) {},
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('关联失败: ${errorToMessage(e)}')),
      ),
    );
  }
}

class _ChannelCard extends ConsumerWidget {
  const _ChannelCard({
    required this.channel,
    required this.accountId,
  });

  final Channel channel;
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protColor =
        _protocolColors[channel.transferProtocol] ?? GwpColors.textMuted;
    final isEnabled = channel.status == ChannelStatus.enabled;

    // Fee description
    String feeDesc = '';
    if (channel.feeRate != null && channel.feeRate! > Decimal.zero) {
      feeDesc += '${(channel.feeRate!.toDouble() * 100).toStringAsFixed(2)}%';
    }
    if (channel.fixedFee != null && channel.fixedFee! > Decimal.zero) {
      if (feeDesc.isNotEmpty) feeDesc += ' + ';
      feeDesc +=
          '${channel.limitCurrency ?? ''} ${channel.fixedFee!.toStringAsFixed(2)}';
    }
    if (feeDesc.isEmpty) feeDesc = '免费';

    return Container(
      padding: const EdgeInsets.all(GwpSpacing.sm),
      decoration: BoxDecoration(
        color: protColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: protColor.withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Protocol badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: protColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                channel.transferProtocol.length > 4
                    ? channel.transferProtocol.substring(0, 4)
                    : channel.transferProtocol,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: protColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: GwpSpacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '费率 $feeDesc'
                  '${channel.dailyLimit != null ? ' · 日限额 ${compactValue(channel.dailyLimit!.toDouble())}' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: GwpColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Status + delete
          Column(
            children: [
              GwpStatusBadge(
                 label: channel.status.labelZh,
                variant: isEnabled
                    ? StatusVariant.positive
                    : StatusVariant.muted,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final r = await ref
                      .read(linkAccountChannelUseCaseProvider)
                      .unlink(
                        accountId: accountId,
                        channelId: channel.id,
                      );
                  if (!context.mounted) return;
                  r.when(
                    ok: (_) {},
                    err: (e) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('移除失败: ${errorToMessage(e)}')),
                    ),
                  );
                },
                child: const Icon(
                  Icons.link_off,
                  size: 16,
                  color: GwpColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GwpSpacing.base, GwpSpacing.md, GwpSpacing.base, GwpSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(GwpSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: GwpColors.textSecondary,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: GwpColors.textMuted),
      ),
    );
  }
}

class _ShowMoreBtn extends StatelessWidget {
  const _ShowMoreBtn({required this.remaining, required this.onPressed});
  final int remaining;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GwpSpacing.sm),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GwpColors.textSecondary,
          side: const BorderSide(color: GwpColors.border, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: GwpSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.expand_more, size: 16),
        label: Text(
          '展开剩余 $remaining 项',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
