import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/repositories/exchange_rate_repository.dart';
import 'package:gwp/domain/usecases/value_assets_in_currency.dart';

class _FakePriceProvider implements PriceProvider {
  _FakePriceProvider(this._rates);
  final Map<String, Decimal> _rates;

  @override
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    if (baseCurrency == quoteCurrency) return Ok(Decimal.one);
    final rate = _rates['${baseCurrency.toUpperCase()}->${quoteCurrency.toUpperCase()}'];
    if (rate == null) return const Err(NotFoundError('no rate'));
    return Ok(rate);
  }
}

Asset _asset({
  required String id,
  required String currency,
  Decimal? marketValue,
  Decimal? costPrice,
}) => Asset(
      id: id,
      accountId: 'acc-1',
      assetType: AssetType.fxAsset,
      quantity: Decimal.one,
      costPrice: costPrice,
      currency: currency,
      marketValue: marketValue,
      status: AssetStatus.holding,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  test('保留原币值并换算为计价货币', () async {
    final useCase = ValueAssetsInCurrencyUseCase(_FakePriceProvider({
      'USD->CNY': Decimal.parse('7.2'),
    }));

    final result = await useCase(
      assets: [
        _asset(id: 'cn', currency: 'CNY', marketValue: Decimal.parse('100')),
        _asset(id: 'us', currency: 'USD', marketValue: Decimal.parse('10')),
      ],
      valuationCurrency: 'CNY',
    );

    expect(result.isOk, isTrue);
    final valued = result.valueOrNull!;
    expect(valued.total, Decimal.parse('172.0'));
    expect(valued.assets[0].nativeValue, Decimal.parse('100'));
    expect(valued.assets[0].valuedAmount, Decimal.parse('100'));
    expect(valued.assets[1].nativeValue, Decimal.parse('10'));
    expect(valued.assets[1].valuedAmount, Decimal.parse('72.0'));
    expect(valued.missingAssetIds, isEmpty);
  });

  test('成本基准会同步换算到计价货币', () async {
    final useCase = ValueAssetsInCurrencyUseCase(_FakePriceProvider({
      'USD->CNY': Decimal.parse('7.2'),
    }));

    final result = await useCase(
      assets: [
        _asset(
          id: 'usd',
          currency: 'USD',
          marketValue: Decimal.parse('110'),
          costPrice: Decimal.parse('100'),
        ),
      ],
      valuationCurrency: 'CNY',
    );

    expect(result.isOk, isTrue);
    final valued = result.valueOrNull!.assets.single;
    expect(valued.nativeCostBasis, Decimal.parse('100'));
    expect(valued.valuedAmount, Decimal.parse('792.0'));
    expect(valued.valuedCostBasis, Decimal.parse('720.0'));
  });

  test('缺失汇率时保留原币值并从统计中剔除', () async {
    final useCase = ValueAssetsInCurrencyUseCase(_FakePriceProvider(const {}));

    final result = await useCase(
      assets: [
        _asset(id: 'usd', currency: 'USD', marketValue: Decimal.parse('10')),
      ],
      valuationCurrency: 'CNY',
    );

    expect(result.isOk, isTrue);
    final valued = result.valueOrNull!;
    expect(valued.total, Decimal.zero);
    expect(valued.assets.single.nativeValue, Decimal.parse('10'));
    expect(valued.assets.single.valuedAmount, isNull);
    expect(valued.assets.single.nativeCostBasis, isNull);
    expect(valued.assets.single.valuedCostBasis, isNull);
    expect(valued.assets.single.isConvertible, isFalse);
    expect(valued.missingAssetIds, ['usd']);
  });
}
