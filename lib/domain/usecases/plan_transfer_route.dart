import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account.dart';
import '../entities/account_channel.dart';
import '../entities/channel.dart';
import '../entities/channel_enums.dart';
import '../repositories/account_channel_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/channel_repository.dart';
import 'channel_rule.dart';

enum RouteObjective { minFee, minHops }

class RouteLeg {
  const RouteLeg({
    required this.channel,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.fee,
    required this.fromCurrency,
    required this.toCurrency,
    this.fxRate,
  });

  final Channel channel;
  final Account fromAccount;
  final Account toAccount;
  final Decimal amount;
  final Decimal fee;
  final String fromCurrency;
  final String toCurrency;
  final Decimal? fxRate;
}

class TransferRoute {
  const TransferRoute({
    required this.legs,
    required this.amount,
    required this.currency,
    this.targetCurrency,
    required this.totalFee,
    required this.totalDebit,
    required this.netCredit,
    required this.objective,
    required this.violations,
    this.alternatives = const [],
  });

  final List<RouteLeg> legs;
  final Decimal amount;
  final String currency;
  final String? targetCurrency;
  final Decimal totalFee;
  final Decimal totalDebit;
  final Decimal netCredit;
  final RouteObjective objective;
  final List<RuleFailure> violations;

  /// Alternative routes (excluding the primary route).
  final List<TransferRoute> alternatives;

  bool get isExecutable => violations.isEmpty && legs.isNotEmpty;
}

/// Multi-currency path planner (Dijkstra on expanded state space).
///
/// **States**: `(accountId, currency)` — keyed as `"$accountId:$currency"`.
///
/// **Two edge types:**
/// 1. **Channel edges**: `(A, C) → (B, C)` — same-currency transfer via shared channel.
/// 2. **FX edges**: `(A, C1) → (A, C2)` — internal account exchange.
///    Only created if `Account.fxSpreadPercent > 0` and a valid FX rate exists
///    for `C1→C2` in [fxRates].
///
/// **Channel edge weight** = fee in source currency.
/// **FX edge weight** = `amount × (fxSpreadPercent / 100)` × `fxRate`.
/// (converted to source currency for minFee comparison).
///
class PlanTransferRouteUseCase {
  PlanTransferRouteUseCase(
    this._accounts,
    this._channels,
    this._accountChannels, {
    ChannelRuleEngine engine = const ChannelRuleEngine(),
    DateTime Function()? now,
  })  : _engine = engine,
        _now = now ?? DateTime.now;

  final AccountRepository _accounts;
  final ChannelRepository _channels;
  final AccountChannelRepository _accountChannels;
  final ChannelRuleEngine _engine;
  final DateTime Function() _now;

  /// Build the set of currencies reachable from [startCcy] via FX edges.
  Set<String> _reachableCurrencies(Account acc, String startCcy,
      Map<String, double> fxRates) {
    final reachable = <String>{startCcy};
    if (acc.fxSpreadPercent <= 0) return reachable;
    for (final entry in fxRates.entries) {
      final parts = entry.key.split('/');
      if (parts.length != 2) continue;
      final from = parts[0];
      final to = parts[1];
      if (from == startCcy) reachable.add(to);
      if (to == startCcy) reachable.add(from);
    }
    return reachable;
  }

  /// FX rate for converting [fromCcy] to [toCcy]. Returns null if unavailable.
  double? _fxRateFor(String fromCcy, String toCcy,
      Map<String, double> fxRates) {
    if (fromCcy == toCcy) return 1.0;
    return fxRates['$fromCcy/$toCcy'];
  }

  Future<Result<TransferRoute, AppError>> call({
    required String sourceAccountId,
    required String targetAccountId,
    required Decimal amount,
    required String currency,
    String? targetCurrency,
    Map<String, double> fxRates = const {},
    RouteObjective objective = RouteObjective.minFee,
    Decimal? todaysCumulativeAmount,
  }) async {
    if (amount <= Decimal.zero) {
      return const Err(ValidationError('amount must be > 0'));
    }
    if (sourceAccountId == targetAccountId) {
      return const Err(
          ValidationError('source and target must be different'));
    }

    final srcR = await _accounts.findById(sourceAccountId);
    if (srcR.isErr) return Err(srcR.errorOrNull!);
    final tgtR = await _accounts.findById(targetAccountId);
    if (tgtR.isErr) return Err(tgtR.errorOrNull!);
    final src = srcR.valueOrNull!;
    final tgt = tgtR.valueOrNull!;

    final tgtCcy = targetCurrency ?? currency;

    final List<Account> allAcc;
    final List<Channel> allCh;
    final List<AccountChannel> allLinks;
    try {
      allAcc = await _accounts.watchAll().first;
      allCh = await _channels.watchAll().first;
      allLinks = await _accountChannels.watchAll().first;
    } catch (e) {
      return Err(UnknownError('load route graph failed: $e'));
    }

    final accById = <String, Account>{
      for (final a in allAcc) a.id: a,
      src.id: src,
      tgt.id: tgt,
    };
    final chanById = {for (final c in allCh) c.id: c};

    final linkByKey = <(String, String), AccountChannel>{
      for (final link in allLinks) (link.accountId, link.channelId): link,
    };

    final byChan = <String, List<String>>{};
    for (final l in allLinks) {
      if (!chanById.containsKey(l.channelId)) continue;
      if (!accById.containsKey(l.accountId)) continue;
      (byChan[l.channelId] ??= []).add(l.accountId);
    }

    final at = _now();
    final adj = <String, List<_Edge>>{};
    _Edge? firstRejectEdge;
    List<RuleFailure>? firstReject;
    ValidationError? firstFeeError;
    bool firstRejectHasFx = false;

    // Build edges
    for (final entry in byChan.entries) {
      final c = chanById[entry.key]!;
      final members = entry.value;
      for (var i = 0; i < members.length; i++) {
        final from = accById[members[i]]!;
        for (var j = 0; j < members.length; j++) {
          if (i == j) continue;
          final to = accById[members[j]]!;
          final link = linkByKey[(from.id, c.id)];
          if (link == null) continue;
          final toLink = linkByKey[(to.id, c.id)];
          final feeError = _feeErrorOf(c, link, amount);
          firstFeeError ??= feeError;
          if (feeError != null) continue; // skip this (from,to) pair
          final fromCurrencies =
              _reachableCurrencies(from, currency, fxRates);
          final toCurrencies = _reachableCurrencies(to, currency, fxRates);
          for (final fc in fromCurrencies) {
            for (final tc in toCurrencies) {
              if (fc != tc) continue;
              final effSrc = _effectiveRegion(from.sovereigntyRegion, link.regionOverride, c);
              final effTgt = _effectiveRegion(to.sovereigntyRegion, toLink?.regionOverride, c);
              final ctx = TransferContext(
                amount: amount,
                currency: fc,
                sourceRegion: effSrc,
                targetRegion: effTgt,
                at: at,
                todaysCumulativeAmount: todaysCumulativeAmount,
              );
              final v = _engine.evaluate(c, ctx);
              final e = _Edge(from: from, to: to, channel: c, link: link,
                  fromCurrency: fc, toCurrency: tc, isFx: false);
              if (v.isEmpty) {
                (adj['${from.id}:$fc'] ??= []).add(e);
              } else if (firstRejectEdge == null || from.id == src.id) {
                firstRejectEdge = e;
                firstReject = v;
              }
            }
          }
        }
      }

      // Add FX edges for accounts on this channel
      for (final memberId in members) {
        final acc = accById[memberId]!;
        if (acc.fxSpreadPercent <= 0) continue;
        for (final entry in fxRates.entries) {
          final parts = entry.key.split('/');
          if (parts.length != 2) continue;
          final fromCcy = parts[0];
          final toCcy = parts[1];
          final rate = entry.value;
          // Forward
          final fwdKey = '${acc.id}:$fromCcy';
          (adj[fwdKey] ??= []).add(_Edge(
            from: acc,
            to: acc,
            channel: null,
            link: null,
            fromCurrency: fromCcy,
            toCurrency: toCcy,
            isFx: true,
            fxRate: rate,
          ));
          // Reverse (approximate: 1/rate)
          final revKey = '${acc.id}:$toCcy';
          (adj[revKey] ??= []).add(_Edge(
            from: acc,
            to: acc,
            channel: null,
            link: null,
            fromCurrency: toCcy,
            toCurrency: fromCcy,
            isFx: true,
            fxRate: 1.0 / rate,
          ));
        }
      }
    }

    final startKey = '${src.id}:$currency';
    final goalKey = '${tgt.id}:$tgtCcy';

    // Primary: Dijkstra finds optimal path (handles FX edges correctly)
    final path = adj.containsKey(startKey)
        ? _dijkstra(
            adj: adj,
            start: startKey,
            goal: goalKey,
            amount: amount,
            objective: objective,
          )
        : null;

    // Enumerate alternatives via DFS for display
    final altPaths = path != null
        ? _allPaths(adj, startKey, goalKey, 5)
            .where((p) => !_samePath(p, path!))
            .toList()
        : <List<_Edge>>[];
    altPaths.sort((a, b) {
      final wa = a.fold<Decimal>(Decimal.zero, (s, e) => s + _weight(e, amount, objective));
      final wb = b.fold<Decimal>(Decimal.zero, (s, e) => s + _weight(e, amount, objective));
      return wa.compareTo(wb);
    });

    if (path == null) {
      if (firstRejectEdge != null && firstReject != null &&
          firstRejectEdge.from.id == sourceAccountId &&
          firstRejectEdge.to.id == targetAccountId) {
        final leg = _legOf(firstRejectEdge, amount);
        return Ok(TransferRoute(
          legs: [leg],
          amount: amount,
          currency: currency,
          targetCurrency: tgtCcy,
          totalFee: leg.fee,
          totalDebit: amount + leg.fee,
          netCredit: amount,
          objective: objective,
          violations: firstReject,
          alternatives: const [],
        ));
      }
      if (firstFeeError != null) return Err(firstFeeError);
      return const Err(NotFoundError('no route between accounts'));
    }

    TransferRoute _buildRoute(List<_Edge> edges) {
      final legs = <RouteLeg>[];
      Decimal totalFee = Decimal.zero;
      Decimal runningAmount = amount;
      for (final e in edges) {
        final leg = _legOf(e, runningAmount);
        legs.add(leg);
        totalFee += leg.fee;
        if (e.isFx && e.fxRate != null) {
          runningAmount = (runningAmount - (e.from.fxFixedFee ?? Decimal.zero)) *
              Decimal.parse((e.fxRate!).toStringAsFixed(6)) *
              (Decimal.one -
                  Decimal.parse(
                      ((e.from.fxSpreadPercent) / 100).toStringAsFixed(6)));
        }
      }
      final effectiveCcy =
          legs.isNotEmpty ? legs.last.toCurrency : tgtCcy;
      return TransferRoute(
        legs: legs,
        amount: amount,
        currency: currency,
        targetCurrency: effectiveCcy,
        totalFee: totalFee,
        totalDebit: amount + totalFee,
        netCredit: runningAmount,
        objective: objective,
        violations: const [],
        alternatives: const [],
      );
    }

    final primary = _buildRoute(path!);
    final alts = altPaths
        .take(4)
        .map((p) => _buildRoute(p))
        .toList(growable: false);

    return Ok(TransferRoute(
      legs: primary.legs,
      amount: primary.amount,
      currency: primary.currency,
      targetCurrency: primary.targetCurrency,
      totalFee: primary.totalFee,
      totalDebit: primary.totalDebit,
      netCredit: primary.netCredit,
      objective: primary.objective,
      violations: primary.violations,
      alternatives: alts,
    ));
  }

  RouteLeg _legOf(_Edge e, Decimal amount) {
    final fee = e.isFx
        ? (amount *
                Decimal.parse(
                    (e.from.fxSpreadPercent / 100).toStringAsFixed(6))) +
            (e.from.fxFixedFee ?? Decimal.zero)
        : _feeOf(e.channel!, e.link!, amount);
    return RouteLeg(
      channel: e.isFx
          ? Channel(
                id: 'fx',
                name: '内部换汇',
                transferProtocol: 'FX',
                status: ChannelStatus.enabled,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
          : e.channel!,
      fromAccount: e.from,
      toAccount: e.to,
      amount: amount,
      fee: fee,
      fromCurrency: e.fromCurrency,
      toCurrency: e.toCurrency,
      fxRate: e.fxRate != null ? Decimal.parse(e.fxRate!.toStringAsFixed(6)) : null,
    );
  }

  bool _samePath(List<_Edge> a, List<_Edge> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].channel?.id != b[i].channel?.id) return false;
      if (a[i].from.id != b[i].from.id) return false;
      if (a[i].to.id != b[i].to.id) return false;
      if (a[i].fromCurrency != b[i].fromCurrency) return false;
      if (a[i].toCurrency != b[i].toCurrency) return false;
    }
    return true;
  }

  /// DFS to enumerate all simple paths from [start] to [goal] within [maxHops].
  List<List<_Edge>> _allPaths(
    Map<String, List<_Edge>> adj,
    String start,
    String goal,
    int maxHops,
  ) {
    final results = <List<_Edge>>[];
    final visitedAccts = <String>{};
    final goalAcct = goal.split(':').first;

    void dfs(String node, List<_Edge> soFar) {
      if (soFar.length >= maxHops) return;
      for (final e in adj[node] ?? const <_Edge>[]) {
        // Allow same-account FX transitions; otherwise avoid cycles
        final nextAcct = e.to.id;
        final isFx = e.from.id == e.to.id;
        if (!isFx && visitedAccts.contains(nextAcct)) continue;
        // Also prevent infinite FX loops
        if (isFx && soFar.isNotEmpty && soFar.last.from.id == e.to.id && soFar.last.to.id == e.from.id && soFar.last.isFx) continue;
        final nextKey = '${e.to.id}:${e.toCurrency}';
        final path = [...soFar, e];
        if (e.to.id == goalAcct) {
          results.add(path);
          continue;
        }
        visitedAccts.add(nextAcct);
        dfs(nextKey, path);
        visitedAccts.remove(nextAcct);
      }
    }

    final startAcct = start.split(':').first;
    visitedAccts.add(startAcct);
    dfs(start, []);
    return results;
  }

  List<_Edge>? _dijkstra({
    required Map<String, List<_Edge>> adj,
    required String start,
    required String goal,
    required Decimal amount,
    required RouteObjective objective,
  }) {
    final dist = <String, Decimal>{start: Decimal.zero};
    final prev = <String, _Edge>{};
    final visited = <String>{};

    String? pickNext() {
      Decimal? best;
      String? bestNode;
      dist.forEach((node, d) {
        if (visited.contains(node)) return;
        if (best == null || d < best!) {
          best = d;
          bestNode = node;
        }
      });
      return bestNode;
    }

    while (true) {
      final u = pickNext();
      if (u == null) break;
      visited.add(u);
      // Accept any currency reaching the target account
      if (u == goal) {
        return _reconstruct(prev, u, start);
      }

      for (final e in adj[u] ?? const <_Edge>[]) {
        final vKey = '${e.to.id}:${e.toCurrency}';
        if (visited.contains(vKey)) continue;
        final w = _weight(e, amount, objective);
        final nd = dist[u]! + w;
        final cur = dist[vKey];
        if (cur == null || nd < cur) {
          dist[vKey] = nd;
          prev[vKey] = e;
        }
      }
    }

    // Find the best path to any currency state of the goal account
    String? bestGoal;
    Decimal? bestDist;
    for (final entry in dist.entries) {
      final goalPrefix = '${goal.split(':').first}:';
      if (!entry.key.startsWith(goalPrefix)) continue;
      if (bestDist == null || entry.value < bestDist) {
        bestDist = entry.value;
        bestGoal = entry.key;
      }
    }
    if (bestGoal == null) return null;
    return _reconstruct(prev, bestGoal!, start);
  }

  List<_Edge>? _reconstruct(
      Map<String, _Edge> prev, String goal, String start) {
    if (!prev.containsKey(goal)) return null;
    final out = <_Edge>[];
    String node = goal;
    final guard = <String>{};
    while (true) {
      final p = prev[node];
      if (p == null) break;
      out.insert(0, p);
      final prevKey = '${p.from.id}:${p.fromCurrency}';
      if (prevKey == start) break;
      if (!guard.add(prevKey)) break;
      node = prevKey;
    }
    if (out.isEmpty ||
        '${out.first.from.id}:${out.first.fromCurrency}' != start) {
      return null;
    }
    return out;
  }

  Decimal _weight(_Edge e, Decimal amount, RouteObjective objective) {
    if (e.isFx) {
      switch (objective) {
        case RouteObjective.minFee:
          return amount *
                  Decimal.parse(
                      (e.from.fxSpreadPercent / 100).toStringAsFixed(6)) +
              (e.from.fxFixedFee ?? Decimal.zero);
        case RouteObjective.minHops:
          return Decimal.one; // FX counts as a hop
      }
    }
    switch (objective) {
      case RouteObjective.minFee:
        return _feeOf(e.channel!, e.link!, amount);
      case RouteObjective.minHops:
        return Decimal.one;
    }
  }

  /// Effective region for an account on a channel:
  /// stored override > account's own region > auto-inferred from channel's allowedRegions.
  static String _effectiveRegion(String acctRegion, String? storedOverride, Channel c) {
    if (storedOverride != null && storedOverride.isNotEmpty) return storedOverride;
    final rule = c.sovereigntyRegionRule;
    final allowedRaw = rule?['allowedRegions'];
    if (allowedRaw is List && allowedRaw.isNotEmpty) {
      final allowed = allowedRaw.map((e) => e.toString().toUpperCase()).toSet();
      if (allowed.contains(acctRegion.toUpperCase())) return acctRegion;
      return allowed.first;
    }
    return acctRegion;
  }

  Decimal _feeOf(Channel c, AccountChannel link, Decimal amount) {
    final rate = link.feeRateOverride ?? c.feeRate ?? Decimal.zero;
    final fixed = link.fixedFeeOverride ?? c.fixedFee ?? Decimal.zero;
    return (amount * rate) + fixed;
  }

  ValidationError? _feeErrorOf(Channel c, AccountChannel link, Decimal amount) {
    final fee = _feeOf(c, link, amount);
    if (fee < Decimal.zero) {
      return const ValidationError('channel fee must be >= 0');
    }
    if (fee >= amount) {
      return const ValidationError('channel fee must be < amount');
    }
    return null;
  }
}

class _Edge {
  const _Edge({
    required this.from,
    required this.to,
    this.channel,
    this.link,
    required this.fromCurrency,
    required this.toCurrency,
    this.isFx = false,
    this.fxRate,
  });
  final Account from;
  final Account to;
  final Channel? channel;
  final AccountChannel? link;
  final String fromCurrency;
  final String toCurrency;
  final bool isFx;
  final double? fxRate;
}
