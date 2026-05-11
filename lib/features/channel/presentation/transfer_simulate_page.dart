import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
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
import '../../../domain/usecases/channel_rule.dart';
import '../../../domain/usecases/plan_transfer_route.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/dict_type.dart';
import 'channel_providers.dart';
import 'channel_topology_view.dart';

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
};

const _protocolIcons = <String, IconData>{
  'SWIFT': Icons.public_outlined,
  'ACH': Icons.account_balance_outlined,
  'SEPA': Icons.euro_outlined,
  'CNAPS': Icons.currency_yuan_outlined,
  'FPS': Icons.bolt_outlined,
  'CHATS': Icons.account_balance_wallet_outlined,
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
  RouteObjective _objective = RouteObjective.minFee;
  bool _compareMode = false;
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

  Future<void> _plan() async {
    final src = _sourceId;
    final tgt = _targetId;
    final amt = Decimal.tryParse(_amountCtrl.text.trim());
    if (src == null || tgt == null || amt == null) {
      setState(() {
        _errorMsg = '请完整填写源/目标账户及金额';
        _route = null;
        _feeRoute = null;
        _hopsRoute = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
      _route = null;
      _feeRoute = null;
      _hopsRoute = null;
    });
    final uc = ref.read(planTransferRouteUseCaseProvider);
    final ccy = _currency.toUpperCase();
    if (_compareMode) {
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
      objective: _objective,
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

        // Pre-compute per-account net worth
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

        // Per-account connected channel count
        final channelCount = <String, int>{};
        for (final l in links) {
          channelCount[l.accountId] = (channelCount[l.accountId] ?? 0) + 1;
        }

        // Source and target accounts
        final srcAccount = _sourceId != null
            ? accounts.cast<Account?>().firstWhere(
                (a) => a!.id == _sourceId,
                orElse: () => null,
              )
            : null;
        final tgtAccount = _targetId != null
            ? accounts.cast<Account?>().firstWhere(
                (a) => a!.id == _targetId,
                orElse: () => null,
              )
            : null;

        return ListView(
          padding: const EdgeInsets.all(GwpSpacing.base),
          children: [
            // ── Transfer flow hero ──
            _TransferFlowHero(
              source: srcAccount,
              target: tgtAccount,
              sourceNetWorth: srcAccount != null
                  ? netWorth[srcAccount.id]
                  : null,
              targetNetWorth: tgtAccount != null
                  ? netWorth[tgtAccount.id]
                  : null,
              amount: _amountCtrl.text.isNotEmpty
                  ? Decimal.tryParse(_amountCtrl.text.trim())
                  : null,
              currency: _currency.toUpperCase(),
              regionIndex: regionIndex,
              onSwap: _swapAccounts,
            ),
            const SizedBox(height: GwpSpacing.md),

            _ChannelSummaryHeader(channels: channels),
            const SizedBox(height: GwpSpacing.md),

            // ── Account pickers (rich cards) ──
            _RichAccountPicker(
              label: '源账户',
              icon: Icons.arrow_upward_rounded,
              iconColor: GwpColors.negative,
              selectedId: _sourceId,
              excludedId: _targetId,
              accounts: accounts,
              netWorth: netWorth,
              assetCount: assetCount,
              channelCount: channelCount,
              regionIndex: regionIndex,
              onChanged: (v) => setState(() => _sourceId = v),
            ),
            const SizedBox(height: GwpSpacing.sm),
            _RichAccountPicker(
              label: '目标账户',
              icon: Icons.arrow_downward_rounded,
              iconColor: GwpColors.positive,
              selectedId: _targetId,
              excludedId: _sourceId,
              accounts: accounts,
              netWorth: netWorth,
              assetCount: assetCount,
              channelCount: channelCount,
              regionIndex: regionIndex,
              onChanged: (v) => setState(() => _targetId = v),
            ),
            const SizedBox(height: GwpSpacing.md),

            // ── Amount + Currency ──
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: '金额',
                      prefixIcon: Icon(Icons.attach_money, size: 18),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ),
                const SizedBox(width: GwpSpacing.md),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currencies =
                          ref
                              .watch(dictEntriesProvider(DictType.currency))
                              .asData
                              ?.value ??
                          const [];
                      return DropdownButtonFormField<String>(
                        initialValue: currencies.any((c) => c.code == _currency)
                            ? _currency
                            : null,
                        decoration: const InputDecoration(
                          labelText: '币种',
                          prefixIcon: Icon(Icons.currency_exchange, size: 18),
                        ),
                        dropdownColor: GwpColors.surface2,
                        isExpanded: true,
                        items: currencies
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text('${c.code} · ${c.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: GwpSpacing.md),

            // ── Objective controls ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GwpSpacing.base,
                vertical: GwpSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: GwpColors.surface1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GwpColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '对比模式',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GwpColors.textPrimary,
                          ),
                        ),
                        const Text(
                          '同时计算费用最低 & 跳数最少',
                          style: TextStyle(
                            fontSize: 12,
                            color: GwpColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _compareMode,
                    onChanged: (v) => setState(() => _compareMode = v),
                  ),
                ],
              ),
            ),
            if (!_compareMode) ...[
              const SizedBox(height: GwpSpacing.md),
              SegmentedButton<RouteObjective>(
                segments: const [
                  ButtonSegment(
                    value: RouteObjective.minFee,
                    icon: Icon(Icons.trending_down, size: 18),
                    label: Text('费用最低'),
                  ),
                  ButtonSegment(
                    value: RouteObjective.minHops,
                    icon: Icon(Icons.linear_scale, size: 18),
                    label: Text('跳数最少'),
                  ),
                ],
                selected: {_objective},
                onSelectionChanged: (s) => setState(() => _objective = s.first),
              ),
            ],
            const SizedBox(height: GwpSpacing.md),

            // ── Topology ──
            const ChannelTopologySection(),
            const SizedBox(height: GwpSpacing.base),

            // ── Plan button ──
            FilledButton.icon(
              onPressed: _loading ? null : _plan,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.route_outlined, size: 18),
              label: Text(_compareMode ? '对比规划' : '规划路径'),
            ),
            const SizedBox(height: GwpSpacing.xl),

            // ── Error ──
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(GwpSpacing.md),
                decoration: BoxDecoration(
                  color: GwpColors.negativeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GwpColors.negative.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: GwpColors.negative,
                    ),
                    const SizedBox(width: GwpSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: GwpColors.negative,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Route results ──
            if (!_compareMode && _route != null)
              _RouteCard(route: _route!, regionIndex: regionIndex, protocolIndex: protocolIndex),
            if (_compareMode)
              _CompareResult(
                feeRoute: _feeRoute,
                hopsRoute: _hopsRoute,
                regionIndex: regionIndex,
                protocolIndex: protocolIndex,
              ),

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _ChannelSummaryHeader extends StatelessWidget {
  const _ChannelSummaryHeader({required this.channels});

  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    final total = channels.length;
    final protocols = channels.map((c) => c.transferProtocol).toSet().length;

    return Container(
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '转账通道概览',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total 条通道 · $protocols 种协议',
                  style: const TextStyle(
                    fontSize: 11,
                    color: GwpColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/channels'),
            icon: const Icon(Icons.swap_horiz_outlined, size: 16),
            label: const Text('通道管理'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Transfer flow hero — visual source→target summary
// ──────────────────────────────────────────────────────────────

class _TransferFlowHero extends StatelessWidget {
  const _TransferFlowHero({
    required this.source,
    required this.target,
    required this.sourceNetWorth,
    required this.targetNetWorth,
    required this.amount,
    required this.currency,
    required this.regionIndex,
    required this.onSwap,
  });

  final Account? source;
  final Account? target;
  final Decimal? sourceNetWorth;
  final Decimal? targetNetWorth;
  final Decimal? amount;
  final String currency;
  final RegionIndex regionIndex;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _endpointChip(source, '源', GwpColors.negative)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.sm),
                child: Column(
                  children: [
                    if (amount != null && amount! > Decimal.zero)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GwpColors.actionPrimary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${Money.format(amount!, currency: currency)} $currency',
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GwpColors.actionPrimary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onSwap,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: GwpColors.surface1,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GwpColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: GwpColors.actionPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _endpointChip(target, '目标', GwpColors.positive)),
            ],
          ),
          // Net worth comparison bar
          if (source != null &&
              target != null &&
              sourceNetWorth != null &&
              targetNetWorth != null &&
              (sourceNetWorth! > Decimal.zero ||
                  targetNetWorth! > Decimal.zero)) ...[
            const SizedBox(height: GwpSpacing.md),
            _netWorthBar(),
          ],
        ],
      ),
    );
  }

  Widget _endpointChip(Account? account, String role, Color accent) {
    if (account == null) {
      return Container(
        padding: const EdgeInsets.all(GwpSpacing.md),
        decoration: BoxDecoration(
          color: GwpColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 24, color: accent),
            const SizedBox(height: 4),
            Text('选择$role账户', style: TextStyle(fontSize: 11, color: accent)),
          ],
        ),
      );
    }
    final typeColor =
        _typeColors[account.accountType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[account.accountType] ?? Icons.account_balance;
    final regionName = regionLabel(regionIndex, account.sovereigntyRegion);
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.sm),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(typeIcon, size: 16, color: typeColor),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 2),
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
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  regionName,
                  style: const TextStyle(
                    fontSize: 9,
                    color: GwpColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _netWorthBar() {
    final sVal = sourceNetWorth?.toDouble() ?? 0;
    final tVal = targetNetWorth?.toDouble() ?? 0;
    final total = sVal + tVal;
    if (total <= 0) return const SizedBox.shrink();
    final sFrac = (sVal / total).clamp(0.0, 1.0);
    final tFrac = (tVal / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              '资产对比',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: GwpColors.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              _compact(sVal),
              style: TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: GwpColors.negative.withValues(alpha: 0.8),
              ),
            ),
            const Text(
              ' vs ',
              style: TextStyle(fontSize: 9, color: GwpColors.textMuted),
            ),
            Text(
              _compact(tVal),
              style: TextStyle(
                fontFamily: GwpTypo.monoFont,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: GwpColors.positive.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Row(
              children: [
                Expanded(
                  flex: (sFrac * 1000).round().clamp(1, 1000),
                  child: Container(
                    color: GwpColors.negative.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  flex: (tFrac * 1000).round().clamp(1, 1000),
                  child: Container(
                    color: GwpColors.positive.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _compact(double val) {
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
    if (val >= 1e3) return '${(val / 1e3).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }
}

// ──────────────────────────────────────────────────────────────
// Rich account picker — visual dropdown with account details
// ──────────────────────────────────────────────────────────────

class _RichAccountPicker extends StatelessWidget {
  const _RichAccountPicker({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selectedId,
    required this.excludedId,
    required this.accounts,
    required this.netWorth,
    required this.assetCount,
    required this.channelCount,
    required this.regionIndex,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String? selectedId;
  final String? excludedId;
  final List<Account> accounts;
  final Map<String, Decimal> netWorth;
  final Map<String, int> assetCount;
  final Map<String, int> channelCount;
  final RegionIndex regionIndex;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedId == null
        ? null
        : accounts.cast<Account?>().firstWhere(
            (a) => a?.id == selectedId,
            orElse: () => null,
          );
    final selectedAssetCount = selected == null ? 0 : (assetCount[selected.id] ?? 0);
    final selectedChannelCount =
        selected == null ? 0 : (channelCount[selected.id] ?? 0);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) => _AccountPickerSheet(
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
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: iconColor),
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: selected == null
            ? const Text(
                '请选择账户',
                style: TextStyle(color: GwpColors.textMuted),
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.institutionName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: GwpColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selected.accountType.labelZh} · ${regionLabel(regionIndex, selected.sovereigntyRegion)} · $selectedAssetCount资产 · $selectedChannelCount通道',
                          style: const TextStyle(
                            fontSize: 10,
                            color: GwpColors.textMuted,
                          ),
                          maxLines: 1,
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
    final typeChoices = widget.accounts.map((a) => a.accountType).toSet().toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final regionChoices = widget.accounts.map((a) => a.sovereigntyRegion).toSet().toList()
      ..sort();

    final filtered = widget.accounts.where((a) {
      if (widget.excludedId != null && a.id == widget.excludedId) return false;
      if (_onlyConnected && (widget.channelCount[a.id] ?? 0) <= 0) return false;
      if (_onlyWithAssets && (widget.assetCount[a.id] ?? 0) <= 0) return false;
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
          bottom: MediaQuery.viewInsetsOf(context).bottom + GwpSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择${widget.label}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              const Text(
                '账户类型',
                style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
              ),
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
              const Text(
                '主权地区',
                style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
              ),
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
                        child: Text(
                          '没有匹配的账户',
                          style: TextStyle(color: GwpColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        final typeColor = _typeColors[a.accountType] ?? GwpColors.actionPrimary;
                        final typeIcon = _typeIcons[a.accountType] ?? Icons.account_balance;
                        final ac = widget.assetCount[a.id] ?? 0;
                        final cc = widget.channelCount[a.id] ?? 0;
                        final isSelected = widget.selectedId == a.id;
                        return ListTile(
                          selected: isSelected,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(typeIcon, size: 16, color: typeColor),
                          ),
                          title: Text(a.institutionName),
                          subtitle: Text(
                            '${a.accountType.labelZh} · ${regionLabel(widget.regionIndex, a.sovereigntyRegion)} · $ac资产 · $cc通道',
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: GwpColors.actionPrimary)
                              : null,
                          onTap: () => Navigator.of(context).pop(a.id),
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
// Compare result (enhanced)
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

class _CompareResult extends StatelessWidget {
  const _CompareResult({
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
    if (feeRoute == null && hopsRoute == null) {
      return const SizedBox.shrink();
    }
    final same =
        feeRoute != null &&
        hopsRoute != null &&
        _routesEqual(feeRoute!, hopsRoute!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(GwpSpacing.md),
          decoration: BoxDecoration(
            color: GwpColors.infoBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GwpColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                same ? Icons.info_outline : Icons.compare_arrows,
                size: 18,
                color: GwpColors.info,
              ),
              const SizedBox(width: GwpSpacing.sm),
              Expanded(
                child: Text(
                  same ? '两种目标得到同一条路径' : '两种目标规划结果不同，已并列展示',
                  style: const TextStyle(fontSize: 13, color: GwpColors.info),
                ),
              ),
            ],
          ),
        ),

        // Fee vs Hops comparison bar
        if (feeRoute != null && hopsRoute != null && !same) ...[
          const SizedBox(height: GwpSpacing.md),
          _FeeCompareBar(feeRoute: feeRoute!, hopsRoute: hopsRoute!),
        ],
        const SizedBox(height: GwpSpacing.md),

        if (same)
          _RouteCard(
            route: feeRoute!,
            compareBadge: '两种目标一致',
            regionIndex: regionIndex,
            protocolIndex: protocolIndex,
          )
        else ...[
          if (feeRoute != null)
            _RouteCard(
              route: feeRoute!,
              compareBadge: '费用最低',
              regionIndex: regionIndex,
              protocolIndex: protocolIndex,
            ),
          if (hopsRoute != null) ...[
            const SizedBox(height: GwpSpacing.md),
            _RouteCard(
              route: hopsRoute!,
              compareBadge: '跳数最少',
              regionIndex: regionIndex,
              protocolIndex: protocolIndex,
            ),
          ],
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Fee comparison bar — visual side-by-side fee + hops
// ──────────────────────────────────────────────────────────────

class _FeeCompareBar extends StatelessWidget {
  const _FeeCompareBar({required this.feeRoute, required this.hopsRoute});

  final TransferRoute feeRoute;
  final TransferRoute hopsRoute;

  @override
  Widget build(BuildContext context) {
    final feeA = feeRoute.totalFee.toDouble();
    final feeB = hopsRoute.totalFee.toDouble();
    final maxFee = feeA > feeB ? feeA : feeB;

    return Container(
      padding: const EdgeInsets.all(GwpSpacing.md),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '费用对比',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GwpColors.textMuted,
            ),
          ),
          const SizedBox(height: GwpSpacing.sm),
          // Min fee route bar
          _compareRow(
            label: '费用最低',
            fee: feeRoute.totalFee,
            hops: feeRoute.legs.length,
            fraction: maxFee > 0 ? feeA / maxFee : 0,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 6),
          // Min hops route bar
          _compareRow(
            label: '跳数最少',
            fee: hopsRoute.totalFee,
            hops: hopsRoute.legs.length,
            fraction: maxFee > 0 ? feeB / maxFee : 0,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(height: GwpSpacing.sm),
          // Delta row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Δ 费用 ${(feeRoute.totalFee - hopsRoute.totalFee).abs()}',
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
              Text(
                'Δ 跳数 ${(feeRoute.legs.length - hopsRoute.legs.length).abs()}',
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compareRow({
    required String label,
    required Decimal fee,
    required int hops,
    required double fraction,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
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
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: GwpColors.surface3,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
            ),
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Text(
          '$fee · $hops跳',
          style: const TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: GwpColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Route card (enhanced with visual timeline)
// ──────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.regionIndex,
    required this.protocolIndex,
    this.compareBadge,
  });

  final TransferRoute route;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;
  final String? compareBadge;

  @override
  Widget build(BuildContext context) {
    final ok = route.isExecutable;
    final objectiveLabel =
        compareBadge ??
        (route.objective == RouteObjective.minFee ? '费用最低' : '跳数最少');
    final borderColor = ok
        ? GwpColors.positive.withValues(alpha: 0.3)
        : GwpColors.negative.withValues(alpha: 0.3);
    final headerBg = ok ? GwpColors.positiveBg : GwpColors.negativeBg;
    final headerFg = ok ? GwpColors.positive : GwpColors.negative;

    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GwpSpacing.base,
              vertical: GwpSpacing.md,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_outline : Icons.error_outline,
                  size: 18,
                  color: headerFg,
                ),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  ok ? '可执行路径' : '存在违规',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: headerFg,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: GwpColors.surface3,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$objectiveLabel · ${route.legs.length} 跳',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(GwpSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual timeline
                if (route.legs.isNotEmpty) ...[
                  _VisualTimeline(
                    route: route,
                    regionIndex: regionIndex,
                    protocolIndex: protocolIndex,
                  ),
                  const SizedBox(height: GwpSpacing.md),
                ],

                // Fee breakdown donut (if multi-hop)
                if (route.legs.length > 1) ...[
                  _FeeBreakdownDonut(route: route),
                  const SizedBox(height: GwpSpacing.md),
                ],

                // Summary KVs
                const Divider(height: GwpSpacing.xl),
                _kv('金额', '${route.amount} ${route.currency}'),
                _kv('总手续费', '${route.totalFee}'),
                _kv('源账户扣款', '${route.totalDebit}'),
                _kv('目标到账', '${route.netCredit}'),

                // Fee rate
                if (route.amount > Decimal.zero)
                  _kv(
                    '费率',
                    '${(route.totalFee.toDouble() / route.amount.toDouble() * 100).toStringAsFixed(3)}%',
                  ),

                if (route.violations.isNotEmpty) ...[
                  const SizedBox(height: GwpSpacing.md),
                  const Text(
                    '违规原因',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GwpColors.negative,
                    ),
                  ),
                  for (final v in route.violations) _violation(v),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 88,
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GwpColors.textPrimary,
              fontFeatures: GwpTypo.tabularFigures,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _violation(RuleFailure f) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '• ${f.code.name} — ${f.message}',
      style: const TextStyle(fontSize: 12, color: GwpColors.negative),
    ),
  );
}

// ──────────────────────────────────────────────────────────────
// Visual timeline — shows route legs as connected steps
// ──────────────────────────────────────────────────────────────

class _VisualTimeline extends StatelessWidget {
  const _VisualTimeline({
    required this.route,
    required this.regionIndex,
    required this.protocolIndex,
  });
  final TransferRoute route;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < route.legs.length; i++) ...[
          _timelineNode(route.legs[i].fromAccount, isFirst: i == 0),
          _timelineLeg(route.legs[i], i),
          if (i == route.legs.length - 1)
            _timelineNode(route.legs[i].toAccount, isLast: true),
        ],
      ],
    );
  }

  Widget _timelineNode(
    Account account, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final typeColor =
        _typeColors[account.accountType] ?? GwpColors.actionPrimary;
    final typeIcon = _typeIcons[account.accountType] ?? Icons.account_balance;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst
                      ? GwpColors.negative
                      : (isLast ? GwpColors.positive : typeColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: GwpColors.surface1, width: 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(typeIcon, size: 12, color: typeColor),
        ),
        const SizedBox(width: GwpSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  account.institutionName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                account.accountType.labelZh,
                style: const TextStyle(
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: regionColor(regionIndex, account.sovereigntyRegion),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                account.sovereigntyRegion,
                style: const TextStyle(
                  fontSize: 10,
                  color: GwpColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineLeg(RouteLeg leg, int idx) {
    final protocolColor =
        _protocolColors[leg.channel.transferProtocol] ??
        GwpColors.actionPrimary;
    final protocolIcon =
        _protocolIcons[leg.channel.transferProtocol] ?? Icons.swap_horiz;
    final protocolName =
        protocolDisplayName(protocolIndex, leg.channel.transferProtocol);
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 40,
            child: Center(
              child: Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      protocolColor.withValues(alpha: 0.6),
                      protocolColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GwpSpacing.sm),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: protocolColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: protocolColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(protocolIcon, size: 14, color: protocolColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${leg.channel.name} · $protocolName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: protocolColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (leg.channel.isBuiltin) ...[
                          const SizedBox(width: 6),
                          const BuiltinBadge(),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '费用 ${leg.fee}',
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Fee breakdown donut (per-leg fee proportions)
// ──────────────────────────────────────────────────────────────

class _FeeBreakdownDonut extends StatelessWidget {
  const _FeeBreakdownDonut({required this.route});
  final TransferRoute route;

  @override
  Widget build(BuildContext context) {
    final slices = <_LegSlice>[];
    for (var i = 0; i < route.legs.length; i++) {
      final leg = route.legs[i];
      final feeD = leg.fee.toDouble();
      if (feeD > 0) {
        final color =
            _protocolColors[leg.channel.transferProtocol] ??
            GwpColors.actionPrimary;
        slices.add(
          _LegSlice(label: leg.channel.name, value: feeD, color: color),
        );
      }
    }
    if (slices.isEmpty) return const SizedBox.shrink();
    final total = slices.fold<double>(0, (s, e) => s + e.value);

    return Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: PieChart(
            PieChartData(
              sections: slices
                  .map(
                    (s) => PieChartSectionData(
                      value: s.value,
                      color: s.color,
                      radius: 10,
                      showTitle: false,
                    ),
                  )
                  .toList(),
              sectionsSpace: 1,
              centerSpaceRadius: 16,
            ),
          ),
        ),
        const SizedBox(width: GwpSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '费用构成',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: GwpColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: GwpColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(s.value / total * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: GwpTypo.monoFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: GwpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegSlice {
  const _LegSlice({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
}
