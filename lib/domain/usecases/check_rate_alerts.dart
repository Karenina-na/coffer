import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/money/money.dart';
import '../../core/result.dart';
import '../entities/domain_event.dart';
import '../entities/event_enums.dart';
import '../entities/exchange_rate.dart';
import '../entities/watched_pair.dart';
import '../events/event_bus.dart';
import '../repositories/event_repository.dart';
import '../repositories/exchange_rate_repository.dart';
import '../repositories/watched_pair_repository.dart';

class RateAlertKind {
  const RateAlertKind._(this.code);
  final String code;

  static const high = RateAlertKind._('high');
  static const low = RateAlertKind._('low');
  static const change = RateAlertKind._('change');
}

class RateAlertRecord {
  const RateAlertRecord({
    required this.pairKey,
    required this.kind,
    required this.rate,
    this.referenceRate,
    this.threshold,
    this.changePct,
  });

  final String pairKey;
  final RateAlertKind kind;
  final Decimal rate;
  final Decimal? referenceRate;
  final Decimal? threshold;
  final Decimal? changePct;
}

/// 扫描所有 WatchedPair：对已设置阈值的币对，取 `exchange_rates` 最近两天
/// 快照，按 high/low/change 三个维度判定是否越阈；越阈则写入一条 RATE_ALERT
/// 事件（幂等键 `RATE_ALERT:{pairKey}:{yyyymmdd}:{kind}`），不重复刷屏。
///
/// 触发路径：
/// - 每次 [RefreshWatchedRatesUseCase] 完成后调用一次；
/// - 也可从首页手动刷新按钮调用。
class CheckRateAlertsUseCase {
  CheckRateAlertsUseCase({
    required WatchedPairRepository watched,
    required ExchangeRateRepository rates,
    required EventRepository events,
    DateTime Function() now = DateTime.now,
    String Function() idGen = _defaultId,
  }) : _watched = watched,
       _rates = rates,
       _events = events,
       _now = now,
       _idGen = idGen;

  final WatchedPairRepository _watched;
  final ExchangeRateRepository _rates;
  final EventRepository _events;
  final DateTime Function() _now;
  final String Function() _idGen;

  static String _defaultId() => const Uuid().v4();

  Future<Result<List<RateAlertRecord>, AppError>> call() async {
    final List<WatchedPair> pairs;
    try {
      pairs = await _watched.listAll();
    } catch (e) {
      return Err(StorageError('读取关注币对失败: $e'));
    }
    final fired = <RateAlertRecord>[];

    for (final p in pairs) {
      if (!p.hasAnyAlert) continue;

      final latestR = await _rates.latestFor(
        baseCurrency: p.baseCurrency,
        quoteCurrency: p.quoteCurrency,
      );
      final latest = latestR.when(ok: (r) => r, err: (_) => null);
      if (latest == null) continue;
      final rate = latest.rate;
      if (rate <= Decimal.zero) continue;

      // 绝对阈值（上沿）
      if (p.thresholdHigh != null && rate >= p.thresholdHigh!) {
        final r = await _emit(
          p,
          RateAlertKind.high,
          rate,
          threshold: p.thresholdHigh,
          asOf: latest.asOfTime,
        );
        if (r != null) fired.add(r);
      }
      // 绝对阈值（下沿）
      if (p.thresholdLow != null && rate <= p.thresholdLow!) {
        final r = await _emit(
          p,
          RateAlertKind.low,
          rate,
          threshold: p.thresholdLow,
          asOf: latest.asOfTime,
        );
        if (r != null) fired.add(r);
      }
      // 波动幅度：拉最近 7 天序列，取相邻两点
      if (p.alertChangePct != null) {
        final prev = await _findPreviousPoint(p.pairKey, latest);
        final prevRate = prev?.rate;
        if (prevRate != null && prevRate > Decimal.zero) {
          final pct = Money.percent(rate - prevRate, prevRate);
          if (pct.abs() >= p.alertChangePct!) {
            final r = await _emit(
              p,
              RateAlertKind.change,
              rate,
              referenceRate: prevRate,
              changePct: pct,
              asOf: latest.asOfTime,
            );
            if (r != null) fired.add(r);
          }
        }
      }
    }

    return Ok(fired);
  }

  Future<ExchangeRate?> _findPreviousPoint(
    String pairKey,
    ExchangeRate latest,
  ) async {
    final since = latest.asOfTime.subtract(const Duration(days: 7));
    late final List<ExchangeRate> list;
    try {
      list = await _rates.querySeriesForPair(pairKey: pairKey, since: since);
    } catch (_) {
      return null;
    }
    if (list.isEmpty) return null;
    // list 按 asOfTime 升序；过滤掉 latest 本身和比它晚的。
    final earlier = list
        .where((r) => r.asOfTime.isBefore(latest.asOfTime))
        .toList();
    return earlier.isEmpty ? null : earlier.last;
  }

  Future<RateAlertRecord?> _emit(
    WatchedPair pair,
    RateAlertKind kind,
    Decimal rate, {
    Decimal? threshold,
    Decimal? referenceRate,
    Decimal? changePct,
    required DateTime asOf,
  }) async {
    final now = _now();
    final dayKey = utcDayKey(asOf);
    final sourceKey =
        '${DomainEventTypes.rateAlert}:${pair.pairKey}:$dayKey:${kind.code}';

    final event = DomainEvent(
      id: _idGen(),
      eventType: DomainEventTypes.rateAlert,
      relatedModel: RelatedModel.account, // 无专属 model，挂 ACCOUNT 以兼容 schema
      relatedId: pair.pairKey,
      triggerTime: now,
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      handler: 'rate-alert',
      sourceKey: sourceKey,
      ackRequirement: AckRequirement.optional,
      handlingNote: jsonEncode({
        'pairKey': pair.pairKey,
        'kind': kind.code,
        'rate': rate.toString(),
        'threshold': ?threshold?.toString(),
        'referenceRate': ?referenceRate?.toString(),
        'changePct': ?changePct?.toString(),
        'asOf': asOf.toIso8601String(),
      }),
      createdAt: now,
      updatedAt: now,
    );

    final r = await _events.record(event);
    return r.when(
      ok: (_) => RateAlertRecord(
        pairKey: pair.pairKey,
        kind: kind,
        rate: rate,
        referenceRate: referenceRate,
        threshold: threshold,
        changePct: changePct,
      ),
      err: (_) => null,
    );
  }
}
