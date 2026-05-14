import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/builtin_badge.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/region_meta.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/protocol_display.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_channel.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/usecases/plan_transfer_route.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/dict_type.dart';
import 'channel_providers.dart';

enum _PlanMode { minFee, minHops, compare }

// ──────────────────────────────────────────────────────────────
// Color / icon maps
// ──────────────────────────────────────────────────────────────

const _typeColors = <AccountType, Color>{
  AccountType.bank: Color(0xFF64748B),
  AccountType.broker: Color(0xFF22C55E),
  AccountType.insurance: Color(0xFFA78BFA),
  AccountType.payment: Color(0xFFF59E0B),
  AccountType.custody: Color(0xFF94A3B8),
  AccountType.cryptoExchange: Color(0xFFFB923C),
  AccountType.cryptoWallet: Color(0xFFEC4899),
};

const _typeIcons = <AccountType, IconData>{
  AccountType.bank: Icons.account_balance_outlined,
  AccountType.broker: Icons.show_chart_outlined,
  AccountType.insurance: Icons.health_and_safety_outlined,
  AccountType.payment: Icons.payment_outlined,
  AccountType.custody: Icons.lock_outlined,
  AccountType.cryptoExchange: Icons.currency_bitcoin_outlined,
  AccountType.cryptoWallet: Icons.wallet_outlined,
};

const _protocolColors = <String, Color>{
  'SWIFT': Color(0xFF64748B),
  'ACH': Color(0xFF22C55E),
  'SEPA': Color(0xFF38BDF8),
  'CNAPS': Color(0xFFEF4444),
  'FPS': Color(0xFFF59E0B),
  'CHATS': Color(0xFF14B8A6),
  'CIPS': Color(0xFFEF4444),
};

/// Body-only widget for embedding inside a parent Scaffold (e.g. HoldingsPage).
class TransferSimulateBody extends ConsumerStatefulWidget {
  const TransferSimulateBody({super.key});

  @override
  ConsumerState<TransferSimulateBody> createState() =>
      _TransferSimulateBodyState();
}

class _TransferSimulateBodyState extends ConsumerState<TransferSimulateBody> {
  final _amountCtrl = TextEditingController();
  String _currency = 'CNY';

  String? _sourceId;
  String? _targetId;
  _PlanMode _planMode = _PlanMode.minFee;
  bool _loading = false;

  TransferRoute? _route;
  TransferRoute? _feeRoute;
  TransferRoute? _hopsRoute;
  String? _errorMsg;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Decimal _parseAmount() {
    var raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return _defaultAmount;
    if (raw.endsWith('.')) raw = raw.substring(0, raw.length - 1);
    if (raw.startsWith('.')) raw = '0$raw';
    return Decimal.tryParse(raw) ?? _defaultAmount;
  }

  static final _defaultAmount = Decimal.fromInt(1000);

  Future<void> _plan() async {
    final src = _sourceId;
    final tgt = _targetId;
    final amt = _parseAmount();
    if (src == null || tgt == null) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
      _route = null;
      _feeRoute = null;
      _hopsRoute = null;
    });
    final uc = ref.read(planTransferRouteUseCaseProvider);
    final ccy = _currency.toUpperCase();
    if (_planMode == _PlanMode.compare) {
      final results = await Future.wait([
        uc(
          sourceAccountId: src,
          targetAccountId: tgt,
          amount: amt,
          currency: ccy,
          objective: RouteObjective.minFee,
        ),
        uc(
          sourceAccountId: src,
          targetAccountId: tgt,
          amount: amt,
          currency: ccy,
          objective: RouteObjective.minHops,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _loading = false;
        results[0].when(ok: (r) => _feeRoute = r, err: (_) {});
        results[1].when(ok: (r) => _hopsRoute = r, err: (_) {});
        if (_feeRoute == null && _hopsRoute == null) {
          _errorMsg =
              results[0].errorOrNull?.message ??
              results[1].errorOrNull?.message ??
              '无可用路径';
        }
      });
      return;
    }
    final result = await uc(
      sourceAccountId: src,
      targetAccountId: tgt,
      amount: amt,
      currency: ccy,
      objective: _planMode == _PlanMode.minHops
          ? RouteObjective.minHops
          : RouteObjective.minFee,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.when(ok: (r) => _route = r, err: (e) => _errorMsg = e.message);
    });
  }

  void _swapAccounts() {
    setState(() {
      final tmp = _sourceId;
      _sourceId = _targetId;
      _targetId = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);
    final assetsAsync = ref.watch(assetListProvider);
    final linksAsync = ref.watch(accountChannelListProvider);
    final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
    final protocolEntries =
        ref.watch(dictEntriesProvider(DictType.transferProtocol)).value ??
        const [];
    final ProtocolIndex protocolIndex = {
      for (final entry in protocolEntries) entry.code: entry,
    };
    return accountsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GwpColors.actionPrimary),
      ),
      error: (e, _) => GwpEmptyState.error(
        message: '加载账户失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(accountListProvider),
      ),
      data: (accounts) {
        if (accounts.length < 2) {
          return const GwpEmptyState(
            icon: Icons.swap_horiz_outlined,
            title: '至少需要两个账户',
            subtitle: '请先添加两个或以上账户才能模拟转账',
          );
        }
        final assets = assetsAsync.when(
          data: (list) => list,
          loading: () => <Asset>[],
          error: (_, _) => <Asset>[],
        );
        final links = linksAsync.when(
          data: (list) => list,
          loading: () => <AccountChannel>[],
          error: (_, _) => <AccountChannel>[],
        );
        final channels = ref.watch(channelListProvider).maybeWhen(
              data: (list) => list,
              orElse: () => const <Channel>[],
            );

        final netWorth = <String, Decimal>{};
        final assetCount = <String, int>{};
        for (final a in assets) {
          final mv = a.marketValue;
          if (mv != null && mv > Decimal.zero) {
            netWorth[a.accountId] =
                (netWorth[a.accountId] ?? Decimal.zero) + mv;
          }
          assetCount[a.accountId] = (assetCount[a.accountId] ?? 0) + 1;
        }

        final channelCount = <String, int>{};
        for (final l in links) {
          channelCount[l.accountId] = (channelCount[l.accountId] ?? 0) + 1;
        }

        final srcAccount = _sourceId != null
            ? accounts.cast<Account?>().firstWhere(
                (a) => a!.id == _sourceId, orElse: () => null)
            : null;
        final tgtAccount = _targetId != null
            ? accounts.cast<Account?>().firstWhere(
                (a) => a!.id == _targetId, orElse: () => null)
            : null;

        final srcChannelIds = links
            .where((l) => l.accountId == _sourceId)
            .map((l) => l.channelId)
            .toSet();
        final tgtChannelIds = links
            .where((l) => l.accountId == _targetId)
            .map((l) => l.channelId)
            .toSet();
        final sharedChannelIds = srcChannelIds.intersection(tgtChannelIds);
        final sharedChannels = channels
            .where((c) => sharedChannelIds.contains(c.id))
            .toList();

        final amountDecimal = _amountCtrl.text.trim().isEmpty
            ? null
            : _parseAmount();
        final srcNetWorth =
            srcAccount != null ? netWorth[srcAccount.id] : null;
        final exceedsBalance = amountDecimal != null &&
            srcNetWorth != null &&
            amountDecimal > srcNetWorth;

        final canPlan = _sourceId != null &&
            _targetId != null &&
            !_loading;

        final hasResult = _planMode != _PlanMode.compare
            ? _route != null
            : (_feeRoute != null || _hopsRoute != null);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            GwpSpacing.base,
            GwpSpacing.md,
            GwpSpacing.base,
            112,
          ),
          children: [
            // ── §1 Account selector bar ──
            _AccountSelectorBar(
              source: srcAccount,
              target: tgtAccount,
              sharedChannels: sharedChannels,
              exceedsBalance: exceedsBalance,
              amount: amountDecimal,
              currency: _currency.toUpperCase(),
              regionIndex: regionIndex,
              accounts: accounts,
              assetCount: assetCount,
              channelCount: channelCount,
              netWorth: netWorth,
              sourceId: _sourceId,
              targetId: _targetId,
              onSwap: _swapAccounts,
              onSourceChanged: (v) => setState(() => _sourceId = v),
              onTargetChanged: (v) => setState(() => _targetId = v),
            ),
            const SizedBox(height: GwpSpacing.md),

            // ── §2 Transfer config row ──
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currencies =
                          ref
                              .watch(dictEntriesProvider(DictType.currency))
                              .asData
                              ?.value ??
                          const [];
                      return TextField(
                        controller: _amountCtrl,
                        decoration: InputDecoration(
                          hintText: '1k',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          prefixIcon: PopupMenuButton<String>(
                            offset: const Offset(0, 48),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              width: 36,
                              padding: const EdgeInsets.only(right: 2),
                              alignment: Alignment.center,
                              child: Text(
                                _currency,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: GwpColors.actionPrimary,
                                  fontFamily: GwpTypo.monoFont,
                                ),
                              ),
                            ),
                            itemBuilder: (_) => currencies
                                .map((c) => PopupMenuItem(
                                      value: c.code,
                                      child: Text(
                                        '${c.code} · ${c.name}',
                                        style: const TextStyle(
                                            fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onSelected: (v) =>
                                setState(() => _currency = v),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
                PopupMenuButton<_PlanMode>(
                  offset: const Offset(0, 48),
                  padding: EdgeInsets.zero,
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: GwpSpacing.sm, vertical: 10),
                    decoration: BoxDecoration(
                      color: GwpColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: GwpColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _planMode == _PlanMode.compare
                              ? Icons.compare_arrows
                              : _planMode == _PlanMode.minHops
                                  ? Icons.linear_scale
                                  : Icons.trending_down,
                          size: 14,
                          color: GwpColors.actionPrimary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _planMode == _PlanMode.compare
                              ? '对比'
                              : _planMode == _PlanMode.minHops
                                  ? '跳数'
                                  : '费用',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GwpColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            size: 14, color: GwpColors.textMuted),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _PlanMode.minFee,
                      child: ListTile(
                        leading: Icon(Icons.trending_down, size: 18),
                        title: Text('费用最低'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: _PlanMode.minHops,
                      child: ListTile(
                        leading: Icon(Icons.linear_scale, size: 18),
                        title: Text('跳数最少'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: _PlanMode.compare,
                      child: ListTile(
                        leading: Icon(Icons.compare_arrows, size: 18),
                        title: Text('对比'),
                        dense: true,
                      ),
                    ),
                  ],
                  onSelected: (v) => setState(() => _planMode = v),
                ),
                const SizedBox(width: GwpSpacing.sm),
                FilledButton.icon(
                  onPressed: canPlan ? _plan : null,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.route_outlined, size: 18),
                  label: const Text('规划'),
                ),
              ],
            ),

            // ── Error ──
            if (_errorMsg != null) ...[
              const SizedBox(height: GwpSpacing.md),
              Container(
                padding: const EdgeInsets.all(GwpSpacing.md),
                decoration: BoxDecoration(
                  color: GwpColors.negativeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: GwpColors.negative.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: GwpColors.negative),
                    const SizedBox(width: GwpSpacing.sm),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              fontSize: 13, color: GwpColors.negative)),
                    ),
                  ],
                ),
              ),
            ],

            // ── §3 Route result ──
            if (hasResult) ...[
              const SizedBox(height: GwpSpacing.lg),
              if (_planMode != _PlanMode.compare && _route != null)
                _RouteFlow(
                  route: _route!,
                  regionIndex: regionIndex,
                  protocolIndex: protocolIndex,
                )
              else if (_planMode == _PlanMode.compare)
                _CompareFlow(
                  feeRoute: _feeRoute,
                  hopsRoute: _hopsRoute,
                  regionIndex: regionIndex,
                  protocolIndex: protocolIndex,
                ),
            ],

            const SizedBox(height: GwpSpacing.lg),

            // ── Channel management link ──
            TextButton.icon(
              onPressed: () => context.push('/channels'),
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: const Text('通道管理'),
            ),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §1  Account selector bar
// ──────────────────────────────────────────────────────────────

class _AccountSelectorBar extends StatelessWidget {
  const _AccountSelectorBar({
    required this.source,
    required this.target,
    required this.sharedChannels,
    required this.exceedsBalance,
    required this.amount,
    required this.currency,
    required this.regionIndex,
    required this.accounts,
    required this.assetCount,
    required this.channelCount,
    required this.netWorth,
    required this.sourceId,
    required this.targetId,
    required this.onSwap,
    required this.onSourceChanged,
    required this.onTargetChanged,
  });

  final Account? source;
  final Account? target;
  final List<Channel> sharedChannels;
  final bool exceedsBalance;
  final Decimal? amount;
  final String currency;
  final RegionIndex regionIndex;
  final List<Account> accounts;
  final Map<String, int> assetCount;
  final Map<String, int> channelCount;
  final Map<String, Decimal> netWorth;
  final String? sourceId;
  final String? targetId;
  final VoidCallback onSwap;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final connected = sharedChannels.isNotEmpty;
    final bothSelected = source != null && target != null;
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GwpColors.surface2,
            GwpColors.actionPrimary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _endpointCard(context, source, '源', GwpColors.negative),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: GwpSpacing.sm),
                child: Column(
                  children: [
                    if (amount != null && amount! > Decimal.zero) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: GwpColors.actionPrimary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_fmtAmount(amount!)} $currency',
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GwpColors.actionPrimary,
                          ),
                        ),
                      ),
                      if (exceedsBalance) ...[
                        const SizedBox(height: 3),
                        const Text('余额不足',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: GwpColors.negative)),
                      ],
                    ],
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onSwap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: GwpColors.surface1,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: GwpColors.border, width: 0.5),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            size: 20, color: GwpColors.actionPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _endpointCard(context, target, '目标', GwpColors.positive),
              ),
            ],
          ),
          // Connectivity
          if (bothSelected) ...[
            const SizedBox(height: GwpSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: GwpSpacing.md, vertical: GwpSpacing.sm),
              decoration: BoxDecoration(
                color: connected ? GwpColors.positiveBg : GwpColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (connected
                          ? GwpColors.positive
                          : GwpColors.warning)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connected
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    size: 14,
                    color:
                        connected ? GwpColors.positive : GwpColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connected
                        ? '${sharedChannels.length} 条共享通道'
                        : '无共享通道 — 需中间账户中转',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          connected ? GwpColors.positive : GwpColors.warning,
                    ),
                  ),
                  if (connected) ...[
                    const SizedBox(width: 6),
                    ...sharedChannels.take(3).map((c) {
                      final protoColor =
                          _protocolColors[c.transferProtocol] ??
                              GwpColors.actionPrimary;
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: protoColor, shape: BoxShape.circle),
                        ),
                      );
                    }),
                    if (sharedChannels.length > 3)
                      Text('+${sharedChannels.length - 3}',
                          style: const TextStyle(
                              fontSize: 9, color: GwpColors.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtAmount(Decimal v) {
    final d = v.toDouble();
    if (d.abs() >= 1e6) return '${(d / 1e6).toStringAsFixed(1)}M';
    if (d.abs() >= 1e3) return '${(d / 1e3).toStringAsFixed(1)}K';
    return d.toStringAsFixed(1);
  }

  Future<void> _openPicker(
      BuildContext ctx, String label, String? selectedId, String? excludedId,
      ValueChanged<String?> onChanged) async {
    final picked = await showModalBottomSheet<String>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _AccountPickerSheet(
        label: label,
        accounts: accounts,
        selectedId: selectedId,
        excludedId: excludedId,
        assetCount: assetCount,
        channelCount: channelCount,
        regionIndex: regionIndex,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  Widget _endpointCard(BuildContext ctx, Account? account, String role, Color accent) {
    final typeColor =
        account != null ? (_typeColors[account.accountType] ?? GwpColors.actionPrimary) : accent;
    final typeIcon =
        account != null ? (_typeIcons[account.accountType] ?? Icons.account_balance) : Icons.add_circle_outline;
    final regionName = account != null ? regionLabel(regionIndex, account.sovereigntyRegion) : '';

    return GestureDetector(
      onTap: () => _openPicker(
        ctx,
        role == '源' ? '源账户' : '目标账户',
        role == '源' ? sourceId : targetId,
        role == '源' ? targetId : sourceId,
        role == '源' ? onSourceChanged : onTargetChanged,
      ),
      child: Container(
        padding: const EdgeInsets.all(GwpSpacing.sm),
        decoration: BoxDecoration(
          color: GwpColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            if (account == null)
              Icon(Icons.add_circle_outline, size: 24, color: accent)
            else ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(typeIcon, size: 18, color: typeColor),
              ),
              const SizedBox(height: 6),
              Text(
                account.institutionName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: regionColor(regionIndex, account.sovereigntyRegion),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${account.accountType.labelZh} · $regionName',
                      style: const TextStyle(
                          fontSize: 9, color: GwpColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (account == null) ...[
              const SizedBox(height: 4),
              Text('选择$role账户',
                  style: TextStyle(fontSize: 11, color: accent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountPickerSheet extends StatefulWidget {
  const _AccountPickerSheet({
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.excludedId,
    required this.assetCount,
    required this.channelCount,
    required this.regionIndex,
  });

  final String label;
  final List<Account> accounts;
  final String? selectedId;
  final String? excludedId;
  final Map<String, int> assetCount;
  final Map<String, int> channelCount;
  final RegionIndex regionIndex;

  @override
  State<_AccountPickerSheet> createState() => _AccountPickerSheetState();
}

class _AccountPickerSheetState extends State<_AccountPickerSheet> {
  final _queryCtrl = TextEditingController();
  String _query = '';
  bool _onlyConnected = true;
  bool _onlyWithAssets = false;
  AccountType? _type;
  String? _region;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeChoices = widget.accounts
        .map((a) => a.accountType)
        .toSet()
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final regionChoices = widget.accounts
        .map((a) => a.sovereigntyRegion)
        .toSet()
        .toList()
      ..sort();

    final filtered = widget.accounts.where((a) {
      if (widget.excludedId != null && a.id == widget.excludedId)
        return false;
      if (_onlyConnected && (widget.channelCount[a.id] ?? 0) <= 0)
        return false;
      if (_onlyWithAssets && (widget.assetCount[a.id] ?? 0) <= 0)
        return false;
      if (_type != null && a.accountType != _type) return false;
      if (_region != null && a.sovereigntyRegion != _region) return false;

      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final haystack = [
        a.institutionName,
        a.accountNo ?? '',
        a.sovereigntyRegion,
        regionLabel(widget.regionIndex, a.sovereigntyRegion),
        a.accountType.labelZh,
        a.accountType.labelBilingual,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList()
      ..sort((a, b) => a.institutionName.compareTo(b.institutionName));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: GwpSpacing.base,
          right: GwpSpacing.base,
          top: GwpSpacing.base,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + GwpSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择${widget.label}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: GwpSpacing.sm),
            TextField(
              controller: _queryCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: '搜索机构、账号、地区、账户类型',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: GwpSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('已接入通道'),
                  selected: _onlyConnected,
                  onSelected: (v) => setState(() => _onlyConnected = v),
                ),
                FilterChip(
                  label: const Text('有资产'),
                  selected: _onlyWithAssets,
                  onSelected: (v) => setState(() => _onlyWithAssets = v),
                ),
              ],
            ),
            const SizedBox(height: GwpSpacing.sm),
            if (typeChoices.isNotEmpty) ...[
              const Text('账户类型',
                  style:
                      TextStyle(fontSize: 11, color: GwpColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _type == null,
                    onSelected: (_) => setState(() => _type = null),
                  ),
                  for (final t in typeChoices)
                    ChoiceChip(
                      label: Text(t.labelZh),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: GwpSpacing.sm),
            ],
            if (regionChoices.isNotEmpty) ...[
              const Text('主权地区',
                  style:
                      TextStyle(fontSize: 11, color: GwpColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _region == null,
                    onSelected: (_) => setState(() => _region = null),
                  ),
                  for (final r in regionChoices)
                    ChoiceChip(
                      label: Text(regionLabel(widget.regionIndex, r)),
                      selected: _region == r,
                      onSelected: (_) => setState(() => _region = r),
                    ),
                ],
              ),
              const SizedBox(height: GwpSpacing.sm),
            ],
            Flexible(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(GwpSpacing.lg),
                        child: Text('没有匹配的账户',
                            style: TextStyle(color: GwpColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        final typeColor =
                            _typeColors[a.accountType] ??
                                GwpColors.actionPrimary;
                        final typeIcon =
                            _typeIcons[a.accountType] ??
                                Icons.account_balance;
                        final ac =
                            widget.assetCount[a.id] ?? 0;
                        final cc =
                            widget.channelCount[a.id] ?? 0;
                        final isSelected =
                            widget.selectedId == a.id;
                        return ListTile(
                          selected: isSelected,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  typeColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(typeIcon,
                                size: 16, color: typeColor),
                          ),
                          title: Text(a.institutionName),
                          subtitle: Text(
                            '${a.accountType.labelZh} · ${regionLabel(widget.regionIndex, a.sovereigntyRegion)} · $ac资产 · $cc通道',
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: GwpColors.actionPrimary)
                              : null,
                          onTap: () =>
                              Navigator.of(context).pop(a.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §3  Route flow — vertical source→…→target pipeline card
// ──────────────────────────────────────────────────────────────

class _RouteFlow extends StatelessWidget {
  const _RouteFlow({
    required this.route,
    required this.regionIndex,
    required this.protocolIndex,
    this.badge,
  });

  final TransferRoute route;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final legs = route.legs;
    if (legs.isEmpty) return const SizedBox.shrink();
    final ok = route.isExecutable;
    final statusColor = ok ? GwpColors.positive : GwpColors.negative;

    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GwpSpacing.base, vertical: GwpSpacing.sm),
            color: ok ? GwpColors.positiveBg : GwpColors.negativeBg,
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  badge ?? (route.objective == RouteObjective.minFee ? '费用最低' : '跳数最少'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
                const Spacer(),
                Text('¥${route.totalFee} · ${legs.length}跳',
                    style: const TextStyle(
                        fontSize: 11, color: GwpColors.textSecondary)),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          // Flow body
          Padding(
            padding: const EdgeInsets.fromLTRB(
                GwpSpacing.base, GwpSpacing.md, GwpSpacing.base, GwpSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < legs.length; i++) ...[
                  _flowAccountRow(legs[i].fromAccount,
                      role: i == 0 ? '源' : '中转',
                      color: i == 0 ? GwpColors.negative : GwpColors.actionPrimary),
                  _flowChannelRow(legs[i]),
                  if (i == legs.length - 1)
                    _flowAccountRow(legs[i].toAccount,
                        role: '目标', color: GwpColors.positive),
                ],
                const SizedBox(height: GwpSpacing.md),
                // Summary
                Row(
                  children: [
                    _kvChip('扣款', '${route.totalDebit}'),
                    const SizedBox(width: 6),
                    _kvChip('到账', '${route.netCredit}'),
                    if (route.amount > Decimal.zero) ...[
                      const SizedBox(width: 6),
                      _kvChip(
                        '费率',
                        '${(route.totalFee.toDouble() / route.amount.toDouble() * 100).toStringAsFixed(2)}%',
                      ),
                    ],
                  ],
                ),
                // Violations
                if (route.violations.isNotEmpty) ...[
                  const SizedBox(height: GwpSpacing.md),
                  for (final v in route.violations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${v.code.name} — ${v.message}',
                          style: const TextStyle(
                              fontSize: 11, color: GwpColors.negative)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowAccountRow(Account account,
      {required String role, required Color color}) {
    final typeColor =
        _typeColors[account.accountType] ?? GwpColors.actionPrimary;
    final typeIcon =
        _typeIcons[account.accountType] ?? Icons.account_balance;
    final regionName = regionLabel(regionIndex, account.sovereigntyRegion);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(typeIcon, size: 14, color: typeColor),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Expanded(
          child: Text(
            account.institutionName,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text('$regionName · ${account.accountType.labelZh}',
            style:
                const TextStyle(fontSize: 10, color: GwpColors.textMuted)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(role,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ],
    );
  }

  Widget _flowChannelRow(RouteLeg leg) {
    final protoColor = _protocolColors[leg.channel.transferProtocol] ??
        GwpColors.actionPrimary;
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Container(width: 1.5, color: protoColor.withValues(alpha: 0.3)),
            const SizedBox(width: GwpSpacing.sm + 26 + GwpSpacing.sm - 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: protoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(leg.channel.transferProtocol,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: protoColor)),
                  if (leg.channel.isBuiltin) ...[
                    const SizedBox(width: 4),
                    const BuiltinBadge(),
                  ],
                  const SizedBox(width: 8),
                  Text('费用 ${leg.fee}',
                      style: const TextStyle(
                          fontFamily: GwpTypo.monoFont,
                          fontSize: 10,
                          color: GwpColors.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: protoColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: GwpColors.surface2,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: GwpColors.textMuted)),
            const SizedBox(height: 1),
            Text(value,
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontFeatures: GwpTypo.tabularFigures,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// §4  Compare flow
// ──────────────────────────────────────────────────────────────

bool _routesEqual(TransferRoute a, TransferRoute b) {
  if (a.legs.length != b.legs.length) return false;
  for (var i = 0; i < a.legs.length; i++) {
    if (a.legs[i].channel.id != b.legs[i].channel.id) return false;
    if (a.legs[i].fromAccount.id != b.legs[i].fromAccount.id) return false;
    if (a.legs[i].toAccount.id != b.legs[i].toAccount.id) return false;
  }
  return true;
}

class _CompareFlow extends StatelessWidget {
  const _CompareFlow({
    required this.feeRoute,
    required this.hopsRoute,
    required this.regionIndex,
    required this.protocolIndex,
  });

  final TransferRoute? feeRoute;
  final TransferRoute? hopsRoute;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;

  @override
  Widget build(BuildContext context) {
    if (feeRoute == null && hopsRoute == null) return const SizedBox.shrink();
    final same = feeRoute != null &&
        hopsRoute != null &&
        _routesEqual(feeRoute!, hopsRoute!);

    if (same) {
      return _RouteFlow(
        route: feeRoute!,
        regionIndex: regionIndex,
        protocolIndex: protocolIndex,
        badge: '两种策略一致',
      );
    }

    final feeDelta = feeRoute != null && hopsRoute != null
        ? (feeRoute!.totalFee - hopsRoute!.totalFee).abs()
        : null;

    return Column(
      children: [
        if (feeDelta != null)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GwpSpacing.md, vertical: GwpSpacing.sm),
            decoration: BoxDecoration(
              color: GwpColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GwpColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows,
                    size: 16, color: GwpColors.info),
                const SizedBox(width: 8),
                Text(
                  '费用最低路线节省 ¥$feeDelta',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textPrimary),
                ),
              ],
            ),
          ),
        if (feeRoute != null) ...[
          const SizedBox(height: GwpSpacing.md),
          _RouteFlow(
            route: feeRoute!,
            regionIndex: regionIndex,
            protocolIndex: protocolIndex,
            badge: '费用最低',
          ),
        ],
        if (hopsRoute != null) ...[
          const SizedBox(height: GwpSpacing.md),
          _RouteFlow(
            route: hopsRoute!,
            regionIndex: regionIndex,
            protocolIndex: protocolIndex,
            badge: '跳数最少',
          ),
        ],
      ],
    );
  }
}

