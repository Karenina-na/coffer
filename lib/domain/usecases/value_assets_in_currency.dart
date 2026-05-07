import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../repositories/exchange_rate_repository.dart';

class ValuedAsset {
  const ValuedAsset({
    required this.asset,
    required this.valuationCurrency,
    required this.nativeValue,
    required this.valuedAmount,
    required this.nativeCostBasis,
    required this.valuedCostBasis,
    required this.conversionRate,
    required this.isConvertible,
  });

  final Asset asset;
  final String valuationCurrency;
  final Decimal? nativeValue;
  final Decimal? valuedAmount;
  final Decimal? nativeCostBasis;
  final Decimal? valuedCostBasis;
  final Decimal? conversionRate;
  final bool isConvertible;

  String get nativeCurrency => asset.currency;
}

class ValuedAssets {
  const ValuedAssets({
    required this.valuationCurrency,
    required this.assets,
    required this.total,
    required this.missingAssetIds,
  });

  final String valuationCurrency;
  final List<ValuedAsset> assets;
  final Decimal total;
  final List<String> missingAssetIds;
}

/// 将资产列表统一换算到指定计价货币，同时保留原币值。
class ValueAssetsInCurrencyUseCase {
  ValueAssetsInCurrencyUseCase(this._priceProvider);

  final PriceProvider _priceProvider;

  Future<Result<ValuedAssets, AppError>> call({
    required List<Asset> assets,
    required String valuationCurrency,
  }) async {
    if (valuationCurrency.trim().isEmpty) {
      return const Err(ValidationError('计价货币不能为空'));
    }

    final base = valuationCurrency.trim().toUpperCase();
    final valued = <ValuedAsset>[];
    final missing = <String>[];
    var total = Decimal.zero;

    for (final asset in assets) {
      final nativeValue = asset.marketValue;
      final nativeCostBasis =
          asset.costPrice != null && asset.quantity > Decimal.zero
              ? asset.costPrice! * asset.quantity
              : null;
      if (nativeValue == null) {
        missing.add(asset.id);
        valued.add(
          ValuedAsset(
            asset: asset,
            valuationCurrency: base,
            nativeValue: null,
            valuedAmount: null,
            nativeCostBasis: nativeCostBasis,
            valuedCostBasis: null,
            conversionRate: null,
            isConvertible: false,
          ),
        );
        continue;
      }

      if (asset.currency.toUpperCase() == base) {
        total += nativeValue;
        valued.add(
          ValuedAsset(
            asset: asset,
            valuationCurrency: base,
            nativeValue: nativeValue,
            valuedAmount: nativeValue,
            nativeCostBasis: nativeCostBasis,
            valuedCostBasis: nativeCostBasis,
            conversionRate: Decimal.one,
            isConvertible: true,
          ),
        );
        continue;
      }

      final rate = await _priceProvider.getRate(
        baseCurrency: asset.currency,
        quoteCurrency: base,
      );
      if (rate.isErr || rate.valueOrNull == null || rate.valueOrNull! <= Decimal.zero) {
        missing.add(asset.id);
        valued.add(
          ValuedAsset(
            asset: asset,
            valuationCurrency: base,
            nativeValue: nativeValue,
            valuedAmount: null,
            nativeCostBasis: nativeCostBasis,
            valuedCostBasis: null,
            conversionRate: null,
            isConvertible: false,
          ),
        );
        continue;
      }

      final valueInBase = nativeValue * rate.valueOrNull!;
      final costBasisInBase =
          nativeCostBasis == null ? null : nativeCostBasis * rate.valueOrNull!;
      total += valueInBase;
      valued.add(
        ValuedAsset(
          asset: asset,
          valuationCurrency: base,
          nativeValue: nativeValue,
          valuedAmount: valueInBase,
          nativeCostBasis: nativeCostBasis,
          valuedCostBasis: costBasisInBase,
          conversionRate: rate.valueOrNull!,
          isConvertible: true,
        ),
      );
    }

    return Ok(
      ValuedAssets(
        valuationCurrency: base,
        assets: valued,
        total: total,
        missingAssetIds: missing,
      ),
    );
  }
}
