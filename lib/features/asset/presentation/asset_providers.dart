import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/providers/asset_providers.dart';
import '../../../core/valuation/valuation_currency_provider.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_cost_history_point.dart';
import '../../../domain/entities/asset_price_history_point.dart';
import '../../../domain/usecases/check_asset_sync_outdated.dart';
import '../../../domain/usecases/create_asset.dart';
import '../../../domain/usecases/refresh_asset_price.dart';
import '../../../domain/usecases/transfer_asset.dart';
import '../../../domain/usecases/update_asset.dart';
import '../../../domain/usecases/value_assets_in_currency.dart';
import '../../../domain/usecases/valuate_asset.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../../domain/valuation/strategies/fixed_income_valuator.dart';
import '../../../domain/valuation/strategies/manual_valuator.dart';
import '../../../domain/valuation/strategies/market_quote_valuator.dart';
import '../../../domain/valuation/valuation_router.dart';
import '../../account/presentation/account_providers.dart';
import '../../event/presentation/event_providers.dart';
import '../../exchange_rate/presentation/exchange_rate_providers.dart';

export '../../../data/providers/asset_providers.dart'
    show
        assetDaoProvider,
        assetRepositoryProvider,
        assetPriceHistoryDaoProvider,
        assetPriceHistoryRepositoryProvider,
        assetCostHistoryDaoProvider,
        assetCostHistoryRepositoryProvider,
        assetPriceProviderProvider;

/// 单个资产的成本/持仓调整历史流（按 triggerTime 降序）。
final assetCostHistoryProvider =
    StreamProvider.family<List<AssetCostHistoryPoint>, String>((ref, assetId) {
      return ref
          .watch(assetCostHistoryRepositoryProvider)
          .watchByAsset(assetId);
    });

final assetListProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(assetRepositoryProvider).watchAll();
});

final assetByIdProvider = StreamProvider.family<Asset?, String>((ref, assetId) {
  return ref.watch(assetRepositoryProvider).watchById(assetId);
});

final valueAssetsInCurrencyUseCaseProvider =
    Provider<ValueAssetsInCurrencyUseCase>((ref) {
      return ValueAssetsInCurrencyUseCase(ref.watch(priceProviderProvider));
    });

final valuedAssetsProvider = FutureProvider.autoDispose<ValuedAssets>((ref) async {
  final assets = await ref.watch(assetListProvider.future);
  final base = ref.watch(valuationCurrencyProvider);
  final useCase = ref.watch(valueAssetsInCurrencyUseCaseProvider);
  final result = await useCase(assets: assets, valuationCurrency: base);
  return result.when(
    ok: (valued) => valued,
    err: (e) => throw Exception('value assets failed: ${e.message}'),
  );
});

final valuedAssetsByAccountProvider =
    FutureProvider.autoDispose.family<ValuedAssets, String>((ref, accountId) async {
      final assets = await ref.watch(assetsByAccountProvider(accountId).future);
      final base = ref.watch(valuationCurrencyProvider);
      final useCase = ref.watch(valueAssetsInCurrencyUseCaseProvider);
      final result = await useCase(assets: assets, valuationCurrency: base);
      return result.when(
        ok: (valued) => valued,
        err: (e) => throw Exception('value account assets failed: ${e.message}'),
      );
    });

final valuedAssetByIdProvider =
    FutureProvider.autoDispose.family<ValuedAsset?, String>((ref, assetId) async {
      final asset = await ref.watch(assetByIdProvider(assetId).future);
      if (asset == null) return null;
      final base = ref.watch(valuationCurrencyProvider);
      final useCase = ref.watch(valueAssetsInCurrencyUseCaseProvider);
      final result = await useCase(assets: [asset], valuationCurrency: base);
      return result.when(
        ok: (valued) => valued.assets.firstOrNull,
        err: (e) => throw Exception('value asset failed: ${e.message}'),
      );
    });

final assetsByAccountProvider = StreamProvider.family<List<Asset>, String>((
  ref,
  accountId,
) {
  return ref.watch(assetRepositoryProvider).watchByAccount(accountId);
});

final createAssetUseCaseProvider = Provider<CreateAssetUseCase>((ref) {
  const uuid = Uuid();
  return CreateAssetUseCase(
    ref.watch(assetRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    idGenerator: uuid.v4,
    now: DateTime.now,
  );
});

final updateAssetUseCaseProvider = Provider<UpdateAssetUseCase>((ref) {
  const uuid = Uuid();
  return UpdateAssetUseCase(
    ref.watch(assetRepositoryProvider),
    ref.watch(assetCostHistoryRepositoryProvider),
    idGenerator: uuid.v4,
    now: DateTime.now,
  );
});

final valuateAssetUseCaseProvider = Provider<ValuateAssetUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ValuateAssetUseCase(
    ref.watch(assetRepositoryProvider),
    ref.watch(assetPriceHistoryRepositoryProvider),
    ref.watch(priceProviderProvider),
    idGenerator: ref.watch(uuidGeneratorProvider),
    now: DateTime.now,
    transaction: <T>(fn) => db.transaction(fn),
  );
});

/// 资产估值路由器：按资产类别分发到不同估值策略。
final assetValuatorProvider = Provider<AssetValuator>((ref) {
  return AssetValuationRouter([
    FixedIncomeValuator(),
    MarketQuoteValuator(source: ref.watch(assetPriceProviderProvider)),
    ManualValuator(),
  ]);
});

/// 抓取外部行情并刷新资产估值（最新价 / 历史序列）。
final refreshAssetPriceUseCaseProvider = Provider<RefreshAssetPriceUseCase>((
  ref,
) {
  return RefreshAssetPriceUseCase(
    assets: ref.watch(assetRepositoryProvider),
    events: ref.watch(eventRepositoryProvider),
    priceHistory: ref.watch(assetPriceHistoryRepositoryProvider),
    bus: ref.watch(domainEventBusProvider),
    fxRates: ref.watch(priceProviderProvider),
    valuator: ref.watch(assetValuatorProvider),
    valuate: ref.watch(valuateAssetUseCaseProvider),
    idGenerator: ref.watch(uuidGeneratorProvider),
    now: DateTime.now,
  );
});

/// 单个资产的估值快照流（按 triggerTime 升序，供图表使用）。
final assetValuationHistoryProvider =
    StreamProvider.family<List<AssetPriceHistoryPoint>, String>((ref, assetId) {
      return ref
          .watch(assetPriceHistoryRepositoryProvider)
          .watchByAsset(assetId);
    });

/// 扫描并写入「同步过期」聚合事件。调用方通常在事件页 initState 触发一次。
final checkAssetSyncOutdatedUseCaseProvider =
    Provider<CheckAssetSyncOutdatedUseCase>((ref) {
      return CheckAssetSyncOutdatedUseCase(
        assets: ref.watch(assetRepositoryProvider),
        events: ref.watch(eventRepositoryProvider),
        bus: ref.watch(domainEventBusProvider),
        idGenerator: ref.watch(uuidGeneratorProvider),
        now: DateTime.now,
      );
    });

final transferAssetUseCaseProvider = Provider<TransferAssetUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransferAssetUseCase(
    ref.watch(assetRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(eventRepositoryProvider),
    ref.watch(assetCostHistoryRepositoryProvider),
    ref.watch(domainEventBusProvider),
    idGenerator: ref.watch(uuidGeneratorProvider),
    now: DateTime.now,
    transaction: <T>(fn) => db.transaction(fn),
  );
});
