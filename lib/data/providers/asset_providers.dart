import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/asset_cost_history_dao.dart';
import '../db/daos/asset_dao.dart';
import '../db/daos/asset_price_history_dao.dart';
import '../repositories/drift_asset_cost_history_repository.dart';
import '../repositories/drift_asset_price_history_repository.dart';
import '../repositories/drift_asset_repository.dart';
import '../../domain/providers/asset_price_provider.dart';
import '../../domain/repositories/asset_cost_history_repository.dart';
import '../../domain/repositories/asset_price_history_repository.dart';
import '../../domain/repositories/asset_repository.dart';
import 'account_providers.dart';
import 'asset/coingecko_provider.dart';
import 'asset/composite_asset_price_provider.dart';
import 'asset/eastmoney_provider.dart';
import 'asset/fund_nav_provider.dart';
import 'asset/yahoo_finance_provider.dart';

final assetDaoProvider = Provider<AssetDao>((ref) {
  return ref.watch(appDatabaseProvider).assetDao;
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return DriftAssetRepository(ref.watch(assetDaoProvider));
});

final assetPriceHistoryDaoProvider = Provider<AssetPriceHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).assetPriceHistoryDao;
});

final assetPriceHistoryRepositoryProvider =
    Provider<AssetPriceHistoryRepository>((ref) {
  return DriftAssetPriceHistoryRepository(
    ref.watch(assetPriceHistoryDaoProvider),
  );
});

final assetCostHistoryDaoProvider = Provider<AssetCostHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).assetCostHistoryDao;
});

final assetCostHistoryRepositoryProvider =
    Provider<AssetCostHistoryRepository>((ref) {
  return DriftAssetCostHistoryRepository(
    ref.watch(assetCostHistoryDaoProvider),
  );
});

/// 资产价格外部数据源：
/// 1. 基金净值（大陆基金走东方财富，香港/全球基金走 Yahoo Finance）
/// 2. 东方财富（国内直连，覆盖沪深港美股、ETF、债券）
/// 3. CoinGecko（加密货币专用，免认证，全球直连）
/// 4. Yahoo Finance（境外网络备用，覆盖全球股票 + 加密货币）
final assetPriceProviderProvider = Provider<AssetPriceProvider>((ref) {
  final fn = FundNavProvider();
  final em = EastmoneyProvider();
  final cg = CoinGeckoProvider();
  final yh = YahooFinanceProvider();
  ref.onDispose(fn.dispose);
  ref.onDispose(em.dispose);
  ref.onDispose(cg.dispose);
  ref.onDispose(yh.dispose);
  return CompositeAssetPriceProvider([fn, em, cg, yh]);
});
