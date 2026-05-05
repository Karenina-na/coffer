import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/exchange_rate_dao.dart';
import '../db/daos/watched_pair_dao.dart';
import '../repositories/drift_exchange_rate_repository.dart';
import '../repositories/drift_watched_pair_repository.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../../domain/repositories/watched_pair_repository.dart';
import 'account_providers.dart';
import 'fx/cached_fx_price_provider.dart';
import 'fx/frankfurter_provider.dart';

final exchangeRateDaoProvider = Provider<ExchangeRateDao>((ref) {
  return ref.watch(appDatabaseProvider).exchangeRateDao;
});

final watchedPairDaoProvider = Provider<WatchedPairDao>((ref) {
  return ref.watch(appDatabaseProvider).watchedPairDao;
});

final exchangeRateImplProvider =
    Provider<DriftExchangeRateRepository>((ref) {
  return DriftExchangeRateRepository(ref.watch(exchangeRateDaoProvider));
});

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ref.watch(exchangeRateImplProvider);
});

/// 价格提供者：本地 DB → 反向换算 → Frankfurter 远端兜底。
final priceProviderProvider = Provider<PriceProvider>((ref) {
  return CachedFxPriceProvider(
    local: ref.watch(exchangeRateImplProvider),
    remote: ref.watch(frankfurterProviderProvider),
  );
});

final watchedPairRepositoryProvider = Provider<WatchedPairRepository>((ref) {
  return DriftWatchedPairRepository(ref.watch(watchedPairDaoProvider));
});

final frankfurterProviderProvider = Provider<FrankfurterProvider>((ref) {
  final p = FrankfurterProvider();
  ref.onDispose(p.dispose);
  return p;
});
