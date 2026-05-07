import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account.dart';
import '../entities/account_channel.dart';
import '../entities/channel.dart';
import '../repositories/account_channel_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/channel_repository.dart';
import 'channel_rule.dart';

/// 多跳转账路径规划的优化目标。
enum RouteObjective {
  /// 总手续费最低。
  minFee,

  /// 经过的 Channel 最少（跳数最少，合规友好）。
  minHops,
}

/// 一条路径上的单段 Channel 跳。
///
/// 节点是具体账户（非账户类型）：两端账户都必须已在该 channel 上登记，
/// 才能成为一条可用边。
class RouteLeg {
  const RouteLeg({
    required this.channel,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.fee,
  });

  final Channel channel;
  final Account fromAccount;
  final Account toAccount;

  /// 进入本段的金额（当前模型下金额沿路径不变）。
  final Decimal amount;

  /// 本段收取的手续费 = amount * feeRate + fixedFee。
  final Decimal fee;
}

/// 规划出的转账路径（可能多跳），替代单跳 [TransferQuote] 的位置。
class TransferRoute {
  const TransferRoute({
    required this.legs,
    required this.amount,
    required this.currency,
    required this.totalFee,
    required this.totalDebit,
    required this.netCredit,
    required this.objective,
    required this.violations,
  });

  final List<RouteLeg> legs;
  final Decimal amount;
  final String currency;
  final Decimal totalFee;
  final Decimal totalDebit;
  final Decimal netCredit;
  final RouteObjective objective;

  /// 若为空即可执行；否则为仅报价。
  final List<RuleFailure> violations;

  bool get isExecutable => violations.isEmpty && legs.isNotEmpty;
}

/// 基于 Channel 拓扑的多跳路径规划器（Dijkstra）。
///
/// 数据模型假设（v2）：
/// - `Channel` 只描述协议/网络本身（SWIFT、微信、支付宝…），不再绑定账户类型；
/// - 账户通过 `AccountChannel` 多对多关联声明自己接入了哪些通道；
/// - 同一通道上任意两个已接入账户都可互转，方向取决于 Dijkstra。
///
/// 算法：把 **账户 id** 当作节点。对每个通道，把登记到它上的所有账户两两构成
/// 有向边（i→j，i≠j），通过 [ChannelRuleEngine] 以 **双端账户 region** 为上下文
/// 逐边评估是否合规；合规边用 [RouteObjective] 选定的权重参与 Dijkstra。
///
/// 简化：
/// - 金额沿路径不变（Channel 模型尚无 FX 转换语义）。
/// - 不允许"零跳"——必须经过至少一个 channel。
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

  Future<Result<TransferRoute, AppError>> call({
    required String sourceAccountId,
    required String targetAccountId,
    required Decimal amount,
    required String currency,
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

    // 仓储 watchAll() 首帧即全量。
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
      // 端点账户可能因软删除未出现在 watchAll 中；仍保留以便输出失败原因。
      src.id: src,
      tgt.id: tgt,
    };
    final chanById = {for (final c in allCh) c.id: c};

    final linkByKey = <(String, String), AccountChannel>{
      for (final link in allLinks) (link.accountId, link.channelId): link,
    };

    // 按 channel 收集成员账户；忽略孤儿关联。
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
          final ctx = TransferContext(
            amount: amount,
            currency: currency,
            sourceRegion: from.sovereigntyRegion,
            targetRegion: to.sovereigntyRegion,
            at: at,
            todaysCumulativeAmount: todaysCumulativeAmount,
          );
          final feeError = _feeErrorOf(c, link, amount);
          if (feeError != null) {
            firstFeeError ??= feeError;
            continue;
          }
          final v = _engine.evaluate(c, ctx);
          final edge = _Edge(from: from, to: to, channel: c, link: link);
          if (v.isEmpty) {
            (adj[from.id] ??= []).add(edge);
          } else {
            // 优先记录从源账户出发的违规边，UI 展示更相关的拒绝原因。
            if (firstRejectEdge == null || from.id == src.id) {
              firstRejectEdge = edge;
              firstReject = v;
            }
          }
        }
      }
    }

    final path = adj.containsKey(src.id)
        ? _dijkstra(
            adj: adj,
            start: src.id,
            goal: tgt.id,
            amount: amount,
            objective: objective,
          )
        : null;

    if (path == null) {
      if (firstRejectEdge != null &&
          firstReject != null &&
          firstRejectEdge.from.id == sourceAccountId &&
          firstRejectEdge.to.id == targetAccountId) {
        final leg = _legOf(firstRejectEdge, amount);
        return Ok(TransferRoute(
          legs: [leg],
          amount: amount,
          currency: currency,
          totalFee: leg.fee,
          totalDebit: amount + leg.fee,
          netCredit: amount,
          objective: objective,
          violations: firstReject,
        ));
      }
      if (firstFeeError != null) {
        return Err(firstFeeError);
      }
      return const Err(NotFoundError('no route between accounts'));
    }

    final legs = <RouteLeg>[];
    Decimal totalFee = Decimal.zero;
    for (final e in path) {
      final leg = _legOf(e, amount);
      legs.add(leg);
      totalFee += leg.fee;
    }
    return Ok(TransferRoute(
      legs: legs,
      amount: amount,
      currency: currency,
      totalFee: totalFee,
      totalDebit: amount + totalFee,
      netCredit: amount,
      objective: objective,
      violations: const [],
    ));
  }

  RouteLeg _legOf(_Edge e, Decimal amount) {
    final fee = _feeOf(e.channel, e.link, amount);
    return RouteLeg(
      channel: e.channel,
      fromAccount: e.from,
      toAccount: e.to,
      amount: amount,
      fee: fee,
    );
  }

  /// Dijkstra on Account-id nodes; 线性选最小（N 通常不大）。
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
      if (u == goal) break;

      for (final e in adj[u] ?? const <_Edge>[]) {
        final v = e.to.id;
        if (visited.contains(v)) continue;
        final w = _weight(e, amount, objective);
        final nd = dist[u]! + w;
        final cur = dist[v];
        if (cur == null || nd < cur) {
          dist[v] = nd;
          prev[v] = e;
        }
      }
    }

    if (!prev.containsKey(goal)) return null;
    final out = <_Edge>[];
    String node = goal;
    final guard = <String>{};
    while (true) {
      final p = prev[node];
      if (p == null) break;
      out.insert(0, p);
      if (p.from.id == start) break;
      if (!guard.add(p.from.id)) break;
      node = p.from.id;
    }
    // 路径重建完整性检查：首跳必须从 start 出发，否则路径不完整。
    if (out.isEmpty || out.first.from.id != start) return null;
    return out;
  }

  Decimal _weight(_Edge e, Decimal amount, RouteObjective objective) {
    switch (objective) {
      case RouteObjective.minFee:
        return _feeOf(e.channel, e.link, amount);
      case RouteObjective.minHops:
        return Decimal.one;
    }
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
    required this.channel,
    required this.link,
  });
  final Account from;
  final Account to;
  final Channel channel;
  final AccountChannel link;
}
