import 'package:decimal/decimal.dart';

import '../entities/channel.dart';
import '../entities/channel_enums.dart';

/// 规则校验失败的类型化原因；便于 UI 国际化。
enum RuleViolation {
  channelDisabled,
  channelNotEffective,
  amountExceedsSingleLimit,
  amountExceedsDailyLimit,
  currencyMismatch,
  regionBlocked,
  regionNotAllowed,
  regionMustMatch;
}

class RuleFailure {
  const RuleFailure(this.code, this.message);
  final RuleViolation code;
  final String message;

  @override
  String toString() => '${code.name}: $message';
}

/// 转账评估上下文。
class TransferContext {
  const TransferContext({
    required this.amount,
    required this.currency,
    required this.sourceRegion,
    required this.targetRegion,
    required this.at,
    this.todaysCumulativeAmount,
  });

  final Decimal amount;
  final String currency;
  final String sourceRegion;
  final String targetRegion;
  final DateTime at;

  /// 今日已累计金额（同币种），用于 dailyLimit 校验；外部聚合传入。
  final Decimal? todaysCumulativeAmount;
}

typedef RulePredicate = RuleFailure? Function(
  Channel channel,
  TransferContext ctx,
);

/// 规则引擎：按顺序执行一组 [RulePredicate]，第一个返回非 null 的失败即终止。
///
/// 默认规则集 [defaultPredicates] 覆盖架构文档描述的所有校验维度，
/// 调用方可替换/扩展以实现自定义 Channel 策略。
class ChannelRuleEngine {
  const ChannelRuleEngine({List<RulePredicate>? predicates})
      : _predicates = predicates ?? defaultPredicates;

  final List<RulePredicate> _predicates;

  /// 返回所有失败（而非短路），便于 UI 一次性展示问题列表。
  List<RuleFailure> evaluate(Channel channel, TransferContext ctx) {
    final out = <RuleFailure>[];
    for (final p in _predicates) {
      final f = p(channel, ctx);
      if (f != null) out.add(f);
    }
    return out;
  }

  static const List<RulePredicate> defaultPredicates = [
    _statusEnabled,
    _withinEffectiveWindow,
    _currencyMatches,
    _withinSingleLimit,
    _withinDailyLimit,
    _regionAllowed,
  ];
}

RuleFailure? _statusEnabled(Channel c, TransferContext _) =>
    c.status == ChannelStatus.enabled
        ? null
        : const RuleFailure(
            RuleViolation.channelDisabled,
            'channel is not ENABLED',
          );

RuleFailure? _withinEffectiveWindow(Channel c, TransferContext ctx) {
  if (c.effectiveFrom != null && ctx.at.isBefore(c.effectiveFrom!)) {
    return const RuleFailure(
      RuleViolation.channelNotEffective,
      'before effectiveFrom',
    );
  }
  if (c.effectiveTo != null && ctx.at.isAfter(c.effectiveTo!)) {
    return const RuleFailure(
      RuleViolation.channelNotEffective,
      'after effectiveTo',
    );
  }
  return null;
}

RuleFailure? _currencyMatches(Channel c, TransferContext ctx) {
  if (c.limitCurrency == null) return null;
  if (c.limitCurrency!.toUpperCase() != ctx.currency.toUpperCase()) {
    return RuleFailure(
      RuleViolation.currencyMismatch,
      'channel limit is ${c.limitCurrency}, but transfer is ${ctx.currency}',
    );
  }
  return null;
}

RuleFailure? _withinSingleLimit(Channel c, TransferContext ctx) {
  if (c.singleLimit == null) return null;
  if (ctx.amount > c.singleLimit!) {
    return RuleFailure(
      RuleViolation.amountExceedsSingleLimit,
      'single limit ${c.singleLimit}',
    );
  }
  return null;
}

RuleFailure? _withinDailyLimit(Channel c, TransferContext ctx) {
  if (c.dailyLimit == null) return null;
  final sofar = ctx.todaysCumulativeAmount ?? Decimal.zero;
  if (sofar + ctx.amount > c.dailyLimit!) {
    return RuleFailure(
      RuleViolation.amountExceedsDailyLimit,
      'daily limit ${c.dailyLimit}, sofar $sofar',
    );
  }
  return null;
}

RuleFailure? _regionAllowed(Channel c, TransferContext ctx) {
  final rule = c.sovereigntyRegionRule;
  if (rule == null) return null;

  final src = ctx.sourceRegion.toUpperCase();
  final tgt = ctx.targetRegion.toUpperCase();

  final blockedRaw = rule['blockedRegions'];
  final blocked = (blockedRaw is List)
          ? blockedRaw.map((e) => e.toString().toUpperCase()).toSet()
          : const <String>{};
  if (blocked.contains(src) || blocked.contains(tgt)) {
    return const RuleFailure(
      RuleViolation.regionBlocked,
      'source or target region is blocked',
    );
  }

  final allowedRaw = rule['allowedRegions'];
  final allowed = (allowedRaw is List)
      ? allowedRaw.map((e) => e.toString().toUpperCase()).toSet()
      : null;
  if (allowed != null) {
    if (!allowed.contains(src) || !allowed.contains(tgt)) {
      return const RuleFailure(
        RuleViolation.regionNotAllowed,
        'source or target region is not in allowedRegions',
      );
    }
  }

  final requireSame = rule['requireSameRegion'] == true;
  if (requireSame && src != tgt) {
    return const RuleFailure(
      RuleViolation.regionMustMatch,
      'source and target must be in the same region',
    );
  }
  return null;
}
