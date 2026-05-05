import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/exchange_rate_providers.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/watched_pair.dart';
import '../../../domain/usecases/check_rate_alerts.dart';
import '../../../domain/usecases/refresh_watched_rates.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../event/presentation/event_providers.dart';

export '../../../data/providers/exchange_rate_providers.dart'
    show
        exchangeRateDaoProvider,
        watchedPairDaoProvider,
        exchangeRateRepositoryProvider,
        priceProviderProvider,
        watchedPairRepositoryProvider,
        frankfurterProviderProvider;

final exchangeRateListProvider = StreamProvider<List<ExchangeRate>>((ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchAll();
});

final watchedPairListProvider = StreamProvider<List<WatchedPair>>((ref) {
  return ref.watch(watchedPairRepositoryProvider).watchAll();
});

final refreshWatchedRatesUseCaseProvider =
    Provider<RefreshWatchedRatesUseCase>((ref) {
  return RefreshWatchedRatesUseCase(
    watchedRepo: ref.watch(watchedPairRepositoryProvider),
    rateRepo: ref.watch(exchangeRateRepositoryProvider),
    provider: ref.watch(frankfurterProviderProvider),
  );
});

final checkRateAlertsUseCaseProvider =
    Provider<CheckRateAlertsUseCase>((ref) {
  return CheckRateAlertsUseCase(
    watched: ref.watch(watchedPairRepositoryProvider),
    rates: ref.watch(exchangeRateRepositoryProvider),
    events: ref.watch(eventRepositoryProvider),
  );
});

/// 当前汇率同步模式（增量 / 全量），由 UI 层切换。
class RateSyncModeNotifier extends Notifier<SyncMode> {
  @override
  SyncMode build() => SyncMode.full;

  void set(SyncMode m) => state = m;
}

final rateSyncModeProvider =
    NotifierProvider<RateSyncModeNotifier, SyncMode>(RateSyncModeNotifier.new);

/// 某币对在最近 7 天窗口内的快照序列（升序，供 sparkline 使用）。
final pairRateSeriesProvider =
    StreamProvider.autoDispose.family<List<ExchangeRate>, String>(
  (ref, pairKey) {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    return ref
        .watch(exchangeRateRepositoryProvider)
        .watchSeriesForPair(pairKey: pairKey, since: since);
  },
);

/// 详情页用：按 `(pairKey, rangeDays)` 取 DB 中窗口内序列。
///
/// `rangeDays <= 0` 表示全部历史。
class PairSeriesQuery {
  const PairSeriesQuery({required this.pairKey, required this.rangeDays});
  final String pairKey;
  final int rangeDays;

  @override
  bool operator ==(Object other) =>
      other is PairSeriesQuery &&
      other.pairKey == pairKey &&
      other.rangeDays == rangeDays;

  @override
  int get hashCode => Object.hash(pairKey, rangeDays);
}

final pairSeriesByRangeProvider = StreamProvider.autoDispose
    .family<List<ExchangeRate>, PairSeriesQuery>((ref, q) {
  final since = q.rangeDays <= 0
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .subtract(Duration(days: q.rangeDays));
  return ref
      .watch(exchangeRateRepositoryProvider)
      .watchSeriesForPair(pairKey: q.pairKey, since: since);
});
