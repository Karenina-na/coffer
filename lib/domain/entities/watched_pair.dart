import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'watched_pair.freezed.dart';

/// 用户关注的币对，驱动 /rates 页的批量拉取与预警。
@freezed
abstract class WatchedPair with _$WatchedPair {
  const factory WatchedPair({
    required String pairKey,
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime createdAt,

    /// 绝对值上沿：最新汇率 ≥ 此值触发 RATE_ALERT（kind=high）。
    Decimal? thresholdHigh,

    /// 绝对值下沿：最新汇率 ≤ 此值触发 RATE_ALERT（kind=low）。
    Decimal? thresholdLow,

    /// 相对波动百分比阈值（正数，如 3.0 表示 ±3%）：若最近两天汇率绝对变动
    /// 超过此百分比，触发 RATE_ALERT（kind=change）。
    Decimal? alertChangePct,
  }) = _WatchedPair;

  const WatchedPair._();

  bool get hasAnyAlert =>
      thresholdHigh != null || thresholdLow != null || alertChangePct != null;
}
