import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../data/providers/exchange_rate_providers.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/watched_pair.dart';
import '../../../domain/usecases/check_rate_alerts.dart';
import '../../../domain/usecases/manage_watched_pair.dart';
import '../../../domain/usecases/refresh_pair_rate.dart';
import '../../../domain/usecases/refresh_watched_rates.dart';
import '../../../domain/usecases/save_manual_rate.dart';
import '../../event/presentation/event_providers.dart';

export '../../../data/providers/exchange_rate_providers.dart'
    show
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

final refreshWatchedRatesUseCaseProvider = Provider<RefreshWatchedRatesUseCase>(
  (ref) {
    return RefreshWatchedRatesUseCase(
      watchedRepo: ref.watch(watchedPairRepositoryProvider),
      rateRepo: ref.watch(exchangeRateRepositoryProvider),
      provider: ref.watch(frankfurterProviderProvider),
    );
  },
);

final refreshPairRateUseCaseProvider = Provider<RefreshPairRateUseCase>((ref) {
  return RefreshPairRateUseCase(
    rates: ref.watch(exchangeRateRepositoryProvider),
    provider: ref.watch(frankfurterProviderProvider),
  );
});

final manageWatchedPairUseCaseProvider = Provider<ManageWatchedPairUseCase>((
  ref,
) {
  return ManageWatchedPairUseCase(
    ref.watch(watchedPairRepositoryProvider),
    ref.watch(dictRepositoryProvider),
  );
});

final saveManualRateUseCaseProvider = Provider<SaveManualRateUseCase>((ref) {
  return SaveManualRateUseCase(
    rates: ref.watch(exchangeRateRepositoryProvider),
    watchedPairs: ref.watch(manageWatchedPairUseCaseProvider),
    dicts: ref.watch(dictRepositoryProvider),
    idGenerator: ref.watch(uuidGeneratorProvider),
    now: DateTime.now,
  );
});

final checkRateAlertsUseCaseProvider = Provider<CheckRateAlertsUseCase>((ref) {
  return CheckRateAlertsUseCase(
    watched: ref.watch(watchedPairRepositoryProvider),
    rates: ref.watch(exchangeRateRepositoryProvider),
    events: ref.watch(eventRepositoryProvider),
  );
});

/// ── 币种国旗 ──────────────────────────────────────────────
/// 从主权地区字典里复用国旗 emoji，币种 → 地区代码的映射为静态常识。
const Map<String, String> _currencyToRegionCode = {
  'USD': 'US',
  'CNY': 'CN',
  'EUR': 'EU',
  'GBP': 'GB',
  'HKD': 'HK',
  'JPY': 'JP',
  'KRW': 'KR',
  'SGD': 'SG',
  'TWD': 'TW',
  'MYR': 'MY',
  'CAD': 'CA',
  'AUD': 'AU',
  'CHF': 'CH',
  'SEK': 'SE',
  'NOK': 'NO',
  'DKK': 'DK',
  'NZD': 'NZ',
  'THB': 'TH',
  'PHP': 'PH',
  'IDR': 'ID',
  'INR': 'IN',
  'BRL': 'BR',
  'MXN': 'MX',
  'ZAR': 'ZA',
  'RUB': 'RU',
  'TRY': 'TR',
  'SAR': 'SA',
  'AED': 'AE',
  'VND': 'VN',
  'PLN': 'PL',
  'CZK': 'CZ',
  'HUF': 'HU',
  'RON': 'RO',
  'BGN': 'BG',
  'ISK': 'IS',
  'HRK': 'HR',
};

/// 币种代码 → 国旗 emoji，读取地区字典的预置旗标。
final currencyFlagProvider = Provider<Map<String, String>>((ref) {
  final index = ref
      .watch(regionMetaIndexProvider)
      .maybeWhen(data: (d) => d, orElse: () => <String, RegionMeta>{});
  final result = <String, String>{};
  _currencyToRegionCode.forEach((currency, regionCode) {
    final flag = index[regionCode]?.flag;
    if (flag != null) result[currency] = flag;
  });
  return result;
});

/// 某币对在最近 7 天窗口内的快照序列（升序，供 sparkline 使用）。
final pairRateSeriesProvider = StreamProvider.autoDispose
    .family<List<ExchangeRate>, String>((ref, pairKey) {
      final now = DateTime.now();
      final since = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7));
      return ref
          .watch(exchangeRateRepositoryProvider)
          .watchSeriesForPair(pairKey: pairKey, since: since);
    });

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
          : DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ).subtract(Duration(days: q.rangeDays));
      return ref
          .watch(exchangeRateRepositoryProvider)
          .watchSeriesForPair(pairKey: q.pairKey, since: since);
    });
