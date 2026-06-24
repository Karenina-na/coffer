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
import '../../../core/ui/coffer_empty_state.dart';
import '../../../core/ui/protocol_display.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_channel.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/usecases/plan_transfer_route.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../exchange_rate/presentation/exchange_rate_providers.dart';
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
  String _targetCurrency = 'CNY';

  String? _sourceId;
  String? _targetId;
  _PlanMode _planMode = _PlanMode.minFee;
  bool _loading = false;

  TransferRoute? _route;
  TransferRoute? _feeRoute;
  TransferRoute? _hopsRoute;
  String? _errorMsg;
  bool _amountExpanded = false;
  Map<String, Decimal> _fxRates = const {};

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
    final tgtCcy = _targetCurrency.toUpperCase();
    final fxRates = Map<String, Decimal>.of(_fxRates);
    if (_planMode == _PlanMode.compare) {
      final results = await Future.wait([
        uc(
          sourceAccountId: src,
          targetAccountId: tgt,
          amount: amt,
          currency: ccy,
          targetCurrency: tgtCcy,
          fxRates: fxRates,
          objective: RouteObjective.minFee,
        ),
        uc(
          sourceAccountId: src,
          targetAccountId: tgt,
          amount: amt,
          currency: ccy,
          targetCurrency: tgtCcy,
          fxRates: fxRates,
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
      targetCurrency: tgtCcy,
      fxRates: fxRates,
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

  static String _fmtAmountText(Decimal v) {
    final d = v.toDouble();
    if (d.abs() >= 1e6) return '${(d / 1e6).toStringAsFixed(1)}M';
    if (d.abs() >= 1e3) return '${(d / 1e3).toStringAsFixed(1)}K';
    return d.toStringAsFixed(1);
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
        child: CircularProgressIndicator(color: CofferColors.actionPrimary),
      ),
      error: (e, _) => CofferEmptyState.error(
        message: '加载账户失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(accountListProvider),
      ),
      data: (accounts) {
        if (accounts.length < 2) {
          return const CofferEmptyState(
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
        final channels = ref
            .watch(channelListProvider)
            .maybeWhen(data: (list) => list, orElse: () => const <Channel>[]);

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
        // Ensure FX rate stream is active (used by both display and planner)
        final fxAsync = ref.watch(exchangeRateListProvider);
        final fxList = fxAsync.maybeWhen(
          data: (d) => d,
          orElse: () => <ExchangeRate>[],
        );
        final builtFx = <String, Decimal>{};
        for (final r in fxList) {
          final rate = r.rate;
          builtFx['${r.baseCurrency}/${r.quoteCurrency}'] = rate;
          if (rate > Decimal.zero) {
            builtFx['${r.quoteCurrency}/${r.baseCurrency}'] =
                (Decimal.one / rate).toDecimal(scaleOnInfinitePrecision: 18);
          }
        }
        _fxRates = builtFx;

        // Estimated target amount from FX rate (look up both directions)
        String? estimatedTarget;
        if (amountDecimal != null && _currency != _targetCurrency) {
          final src = _currency;
          final tgt = _targetCurrency;
          Decimal? estRate;
          for (final r in fxList) {
            if (r.baseCurrency == src && r.quoteCurrency == tgt) {
              estRate = r.rate;
              break;
            }
            if (r.baseCurrency == tgt && r.quoteCurrency == src) {
              if (r.rate > Decimal.zero) {
                estRate = (Decimal.one / r.rate).toDecimal(
                  scaleOnInfinitePrecision: 18,
                );
              }
              break;
            }
          }
          if (estRate != null) {
            estimatedTarget = _fmtAmountText(amountDecimal * estRate);
          }
        }
        final srcNetWorth = srcAccount != null ? netWorth[srcAccount.id] : null;
        final exceedsBalance =
            amountDecimal != null &&
            srcNetWorth != null &&
            amountDecimal > srcNetWorth;

        final canPlan = _sourceId != null && _targetId != null && !_loading;

        final hasResult = _planMode != _PlanMode.compare
            ? _route != null
            : (_feeRoute != null || _hopsRoute != null);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            CofferSpacing.base,
            CofferSpacing.md,
            CofferSpacing.base,
            112,
          ),
          children: [
            // ── §1 Account selector bar ──
            _AccountSelectorBar(
              source: srcAccount,
              target: tgtAccount,
              sharedChannels: sharedChannels,
              totalPaths: hasResult
                  ? (_planMode != _PlanMode.compare
                        ? (1 + (_route?.alternatives.length ?? 0))
                        : ((_feeRoute != null ? 1 : 0) +
                              (_hopsRoute != null ? 1 : 0) +
                              (_feeRoute?.alternatives.length ?? 0) +
                              (_hopsRoute?.alternatives.length ?? 0)))
                  : null,
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
            const SizedBox(height: CofferSpacing.md),

            // ── §2 Transfer amount (expandable) ──
            Container(
              decoration: BoxDecoration(
                color: CofferColors.surface1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CofferColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: _amountExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(8))
                        : BorderRadius.circular(8),
                    onTap: () =>
                        setState(() => _amountExpanded = !_amountExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: CofferColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _amountCtrl.text.isEmpty
                                ? '1k'
                                : _fmtAmountText(_parseAmount()),
                            style: const TextStyle(
                              fontFamily: CofferTypo.monoFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: CofferColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: CofferColors.actionPrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _currency,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CofferColors.actionPrimary,
                                fontFamily: CofferTypo.monoFont,
                              ),
                            ),
                          ),
                          if (_targetCurrency != _currency) ...[
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: CofferColors.textMuted,
                            ),
                            if (estimatedTarget != null)
                              Text(
                                ' $estimatedTarget ',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: CofferColors.textSecondary,
                                  fontFamily: CofferTypo.monoFont,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: CofferColors.warning.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                _targetCurrency,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: CofferColors.warning,
                                  fontFamily: CofferTypo.monoFont,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            _amountExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: CofferColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_amountExpanded) ...[
                    const Divider(height: 1),
                    _AmountPanel(
                      amountCtrl: _amountCtrl,
                      currency: _currency,
                      targetCurrency: _targetCurrency,
                      onCurrencyChanged: (v) => setState(() => _currency = v),
                      onTargetCurrencyChanged: (v) =>
                          setState(() => _targetCurrency = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: CofferSpacing.sm),

            // ── §3 Strategy + plan ──
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<_PlanMode>(
                    segments: const [
                      ButtonSegment(
                        value: _PlanMode.minFee,
                        icon: Icon(Icons.trending_down, size: 16),
                        label: Text('费用', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: _PlanMode.minHops,
                        icon: Icon(Icons.linear_scale, size: 16),
                        label: Text('跳数', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: _PlanMode.compare,
                        icon: Icon(Icons.compare_arrows, size: 16),
                        label: Text('对比', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_planMode},
                    onSelectionChanged: (s) =>
                        setState(() => _planMode = s.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: CofferSpacing.sm),
                FilledButton.icon(
                  onPressed: canPlan ? _plan : null,
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
                  label: const Text('规划'),
                ),
              ],
            ),

            // ── Error ──
            if (_errorMsg != null) ...[
              const SizedBox(height: CofferSpacing.md),
              Container(
                padding: const EdgeInsets.all(CofferSpacing.md),
                decoration: BoxDecoration(
                  color: CofferColors.negativeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CofferColors.negative.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: CofferColors.negative,
                    ),
                    const SizedBox(width: CofferSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CofferColors.negative,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── §3 Route result ──
            if (hasResult) ...[
              const SizedBox(height: CofferSpacing.lg),
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

            const SizedBox(height: CofferSpacing.lg),

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
    this.totalPaths,
  });

  final Account? source;
  final Account? target;
  final List<Channel> sharedChannels;
  final int? totalPaths;
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
      padding: const EdgeInsets.all(CofferSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CofferColors.surface2,
            CofferColors.actionPrimary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CofferColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _endpointCard(
                  context,
                  source,
                  '源',
                  CofferColors.negative,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CofferSpacing.sm,
                ),
                child: Column(
                  children: [
                    if (amount != null && amount! > Decimal.zero) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CofferColors.actionPrimary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_fmtAmount(amount!)} $currency',
                          style: const TextStyle(
                            fontFamily: CofferTypo.monoFont,
                            fontFeatures: CofferTypo.tabularFigures,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CofferColors.actionPrimary,
                          ),
                        ),
                      ),
                      if (exceedsBalance) ...[
                        const SizedBox(height: 3),
                        const Text(
                          '余额不足',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: CofferColors.negative,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onSwap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CofferColors.surface1,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CofferColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 20,
                          color: CofferColors.actionPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _endpointCard(
                  context,
                  target,
                  '目标',
                  CofferColors.positive,
                ),
              ),
            ],
          ),
          // Connectivity / Paths
          if (bothSelected) ...[
            const SizedBox(height: CofferSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CofferSpacing.md,
                vertical: CofferSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: connected || (totalPaths != null && totalPaths! > 0)
                    ? CofferColors.positiveBg
                    : CofferColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (connected || (totalPaths != null && totalPaths! > 0)
                              ? CofferColors.positive
                              : CofferColors.warning)
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    totalPaths != null
                        ? Icons.alt_route_rounded
                        : connected
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    size: 14,
                    color: connected || (totalPaths != null && totalPaths! > 0)
                        ? CofferColors.positive
                        : CofferColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    totalPaths != null && totalPaths! > 0
                        ? '$totalPaths 条可用路径'
                        : connected
                        ? '${sharedChannels.length} 条共享通道'
                        : '无共享通道 — 需中间账户中转',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          connected || (totalPaths != null && totalPaths! > 0)
                          ? CofferColors.positive
                          : CofferColors.warning,
                    ),
                  ),
                  if (connected) ...[
                    const SizedBox(width: 6),
                    ...sharedChannels.take(3).map((c) {
                      final protoColor =
                          _protocolColors[c.transferProtocol] ??
                          CofferColors.actionPrimary;
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: protoColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                    if (sharedChannels.length > 3)
                      Text(
                        '+${sharedChannels.length - 3}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: CofferColors.textMuted,
                        ),
                      ),
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
    BuildContext ctx,
    String label,
    String? selectedId,
    String? excludedId,
    ValueChanged<String?> onChanged,
  ) async {
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

  Widget _endpointCard(
    BuildContext ctx,
    Account? account,
    String role,
    Color accent,
  ) {
    final typeColor = account != null
        ? (_typeColors[account.accountType] ?? CofferColors.actionPrimary)
        : accent;
    final typeIcon = account != null
        ? (_typeIcons[account.accountType] ?? Icons.account_balance)
        : Icons.add_circle_outline;
    final regionName = account != null
        ? regionLabel(regionIndex, account.sovereigntyRegion)
        : '';

    return GestureDetector(
      onTap: () => _openPicker(
        ctx,
        role == '源' ? '源账户' : '目标账户',
        role == '源' ? sourceId : targetId,
        role == '源' ? targetId : sourceId,
        role == '源' ? onSourceChanged : onTargetChanged,
      ),
      child: Container(
        padding: const EdgeInsets.all(CofferSpacing.sm),
        decoration: BoxDecoration(
          color: CofferColors.surface1,
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
                  color: CofferColors.textPrimary,
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
                      color: regionColor(
                        regionIndex,
                        account.sovereigntyRegion,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${account.accountType.labelZh} · $regionName',
                      style: const TextStyle(
                        fontSize: 9,
                        color: CofferColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (account == null) ...[
              const SizedBox(height: 4),
              Text('选择$role账户', style: TextStyle(fontSize: 11, color: accent)),
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
    final typeChoices =
        widget.accounts.map((a) => a.accountType).toSet().toList()
          ..sort((a, b) => a.code.compareTo(b.code));
    final regionChoices =
        widget.accounts.map((a) => a.sovereigntyRegion).toSet().toList()
          ..sort();

    final filtered = widget.accounts.where((a) {
      if (widget.excludedId != null && a.id == widget.excludedId) {
        return false;
      }
      if (_onlyConnected && (widget.channelCount[a.id] ?? 0) <= 0) {
        return false;
      }
      if (_onlyWithAssets && (widget.assetCount[a.id] ?? 0) <= 0) {
        return false;
      }
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
    }).toList()..sort((a, b) => a.institutionName.compareTo(b.institutionName));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: CofferSpacing.base,
          right: CofferSpacing.base,
          top: CofferSpacing.base,
          bottom: MediaQuery.viewInsetsOf(context).bottom + CofferSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择${widget.label}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: CofferSpacing.sm),
            TextField(
              controller: _queryCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: '搜索机构、账号、地区、账户类型',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: CofferSpacing.sm),
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
            const SizedBox(height: CofferSpacing.sm),
            if (typeChoices.isNotEmpty) ...[
              const Text(
                '账户类型',
                style: TextStyle(fontSize: 11, color: CofferColors.textMuted),
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
              const SizedBox(height: CofferSpacing.sm),
            ],
            if (regionChoices.isNotEmpty) ...[
              const Text(
                '主权地区',
                style: TextStyle(fontSize: 11, color: CofferColors.textMuted),
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
              const SizedBox(height: CofferSpacing.sm),
            ],
            Flexible(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(CofferSpacing.lg),
                        child: Text(
                          '没有匹配的账户',
                          style: TextStyle(color: CofferColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        final typeColor =
                            _typeColors[a.accountType] ??
                            CofferColors.actionPrimary;
                        final typeIcon =
                            _typeIcons[a.accountType] ?? Icons.account_balance;
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
                              ? const Icon(
                                  Icons.check_circle,
                                  color: CofferColors.actionPrimary,
                                )
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
    final statusColor = ok ? CofferColors.positive : CofferColors.negative;
    final multiCcy =
        route.targetCurrency != null && route.targetCurrency != route.currency;

    return Container(
      decoration: BoxDecoration(
        color: CofferColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CofferSpacing.base,
              vertical: CofferSpacing.sm,
            ),
            color: ok ? CofferColors.positiveBg : CofferColors.negativeBg,
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_outline : Icons.error_outline,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  badge ??
                      (route.objective == RouteObjective.minFee
                          ? '费用最低'
                          : '跳数最少'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                if (multiCcy)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: CofferColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${route.currency} → ${route.targetCurrency}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: CofferColors.warning,
                        fontFamily: CofferTypo.monoFont,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${route.totalFee.toStringAsFixed(2)} · ${legs.length}跳',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CofferColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Flow body
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CofferSpacing.base,
              CofferSpacing.md,
              CofferSpacing.base,
              CofferSpacing.sm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < legs.length; i++) ...[
                  _flowAccountRow(
                    legs[i].fromAccount,
                    role: i == 0 ? '源' : '中转',
                    currency: legs[i].fromCurrency,
                    color: i == 0
                        ? CofferColors.negative
                        : CofferColors.actionPrimary,
                  ),
                  _flowChannelRow(legs[i]),
                  if (i == legs.length - 1)
                    _flowAccountRow(
                      legs[i].toAccount,
                      role: '目标',
                      currency: legs[i].toCurrency,
                      color: CofferColors.positive,
                    ),
                ],
                const SizedBox(height: CofferSpacing.md),
                // Summary
                Container(
                  padding: const EdgeInsets.all(CofferSpacing.sm),
                  decoration: BoxDecoration(
                    color: CofferColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _sumItem(
                        '扣款',
                        '${route.totalDebit.toStringAsFixed(2)} ${route.currency}',
                      ),
                      const SizedBox(width: CofferSpacing.md),
                      _sumItem(
                        '到账',
                        '${route.netCredit.toStringAsFixed(2)} ${route.targetCurrency ?? route.currency}',
                      ),
                      if (route.amount > Decimal.zero) ...[
                        const SizedBox(width: CofferSpacing.md),
                        _sumItem(
                          '费率',
                          '${(route.totalFee.toDouble() / route.amount.toDouble() * 100).toStringAsFixed(2)}%',
                        ),
                      ],
                    ],
                  ),
                ),
                // Violations
                if (route.violations.isNotEmpty) ...[
                  const SizedBox(height: CofferSpacing.md),
                  for (final v in route.violations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${v.code.name} — ${v.message}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CofferColors.negative,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: CofferColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: CofferTypo.monoFont,
            fontFeatures: CofferTypo.tabularFigures,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CofferColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _flowAccountRow(
    Account account, {
    required String role,
    required String currency,
    required Color color,
  }) {
    final typeColor =
        _typeColors[account.accountType] ?? CofferColors.actionPrimary;
    final typeIcon = _typeIcons[account.accountType] ?? Icons.account_balance;
    final regionName = regionLabel(regionIndex, account.sovereigntyRegion);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
          const SizedBox(width: CofferSpacing.sm),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(typeIcon, size: 14, color: typeColor),
          ),
          const SizedBox(width: CofferSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.institutionName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CofferColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$regionName · ${account.accountType.labelZh}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CofferColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              currency,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: CofferTypo.monoFont,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowChannelRow(RouteLeg leg) {
    final isFx = leg.channel.transferProtocol == 'FX';
    final protoColor = isFx
        ? CofferColors.warning
        : (_protocolColors[leg.channel.transferProtocol] ??
              CofferColors.actionPrimary);
    final protoName = isFx
        ? ''
        : protocolDisplayName(protocolIndex, leg.channel.transferProtocol);
    final indent = isFx ? 28.0 : 0.0; // indent FX under the account
    return Padding(
      padding: EdgeInsets.only(left: 5 + indent),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Container(width: 1.5, color: protoColor.withValues(alpha: 0.25)),
            const SizedBox(width: CofferSpacing.sm + 28 + CofferSpacing.sm - 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: protoColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: isFx
                      ? Border.all(
                          color: protoColor.withValues(alpha: 0.2),
                          width: 0.5,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    if (isFx) ...[
                      Icon(
                        Icons.currency_exchange,
                        size: 12,
                        color: protoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${leg.fromCurrency} → ${leg.toCurrency}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: protoColor,
                        ),
                      ),
                      if (leg.fxRate != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '@${leg.fxRate!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontFamily: CofferTypo.monoFont,
                            fontSize: 8,
                            color: CofferColors.textMuted,
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: protoColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${leg.channel.transferProtocol} · $protoName',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: protoColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (leg.channel.isBuiltin) ...[
                        const SizedBox(width: 3),
                        const BuiltinBadge(),
                      ],
                    ],
                    const Spacer(),
                    Text(
                      isFx
                          ? '损耗 ${leg.fee.toStringAsFixed(2)}'
                          : leg.fee.toStringAsFixed(2),
                      style: TextStyle(
                        fontFamily: CofferTypo.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isFx
                            ? CofferColors.warning
                            : CofferColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: protoColor,
                    ),
                  ],
                ),
              ),
            ),
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
    final same =
        feeRoute != null &&
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
              horizontal: CofferSpacing.md,
              vertical: CofferSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: CofferColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CofferColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.compare_arrows,
                  size: 16,
                  color: CofferColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  '费用最低路线节省 ¥$feeDelta',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CofferColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        if (feeRoute != null) ...[
          const SizedBox(height: CofferSpacing.md),
          _RouteFlow(
            route: feeRoute!,
            regionIndex: regionIndex,
            protocolIndex: protocolIndex,
            badge: '费用最低',
          ),
        ],
        if (hopsRoute != null) ...[
          const SizedBox(height: CofferSpacing.md),
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

// ──────────────────────────────────────────────────────────────
// Amount panel (expandable inline)
// ──────────────────────────────────────────────────────────────

class _AmountPanel extends ConsumerWidget {
  const _AmountPanel({
    required this.amountCtrl,
    required this.currency,
    required this.targetCurrency,
    required this.onCurrencyChanged,
    required this.onTargetCurrencyChanged,
  });

  final TextEditingController amountCtrl;
  final String currency;
  final String targetCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onTargetCurrencyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref
        .watch(dictEntriesProvider(DictType.currency))
        .maybeWhen(data: (d) => d, orElse: () => const []);
    return Padding(
      padding: const EdgeInsets.all(CofferSpacing.sm),
      child: Column(
        children: [
          TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(hintText: '金额', isDense: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: CofferSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currencies.any((c) => c.code == currency)
                      ? currency
                      : null,
                  decoration: const InputDecoration(
                    labelText: '源币种',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: CofferColors.surface2,
                  items: currencies
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.code,
                          child: Text(
                            '${c.code} · ${c.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onCurrencyChanged(v);
                  },
                ),
              ),
              const SizedBox(width: CofferSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currencies.any((c) => c.code == targetCurrency)
                      ? targetCurrency
                      : null,
                  decoration: InputDecoration(
                    labelText: '目标币种',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    labelStyle: TextStyle(
                      color: targetCurrency != currency
                          ? CofferColors.warning
                          : CofferColors.textMuted,
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: CofferColors.surface2,
                  items: currencies
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.code,
                          child: Text(
                            c.code,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onTargetCurrencyChanged(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
