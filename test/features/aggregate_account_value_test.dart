import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/repositories/exchange_rate_repository.dart';
import 'package:gwp/domain/usecases/aggregate_account_value.dart';

class _FakePriceProvider implements PriceProvider {
  _FakePriceProvider(this._rates);
  final Map<String, Decimal> _rates; // key: "BASE->QUOTE"

  @override
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    if (baseCurrency == quoteCurrency) return Ok(Decimal.one);
    final r = _rates['${baseCurrency.toUpperCase()}->${quoteCurrency.toUpperCase()}'];
    if (r == null) return const Err(NotFoundError('no rate'));
    return Ok(r);
  }
}

Asset _asset({
  required String id,
  required Decimal? marketValue,
  required String currency,
}) =>
    Asset(
      id: id,
      accountId: 'acc-1',
      assetType: AssetType.fxAsset,
      quantity: Decimal.fromInt(1),
      currency: currency,
      marketValue: marketValue,
      status: AssetStatus.holding,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  test('同币种直接累加，跨币种走汇率，缺汇率计入 missingRates', () async {
    final usecase = AggregateAccountValueUseCase(_FakePriceProvider({
      'USD->CNY': Decimal.parse('7.2'),
      // HKD->CNY 缺失
    }));

    final result = await usecase(
      baseCurrency: 'CNY',
      assets: [
        _asset(id: 'a1', marketValue: Decimal.parse('100'), currency: 'CNY'),
        _asset(id: 'a2', marketValue: Decimal.parse('10'), currency: 'USD'),
        _asset(id: 'a3', marketValue: Decimal.parse('50'), currency: 'HKD'),
        _asset(id: 'a4', marketValue: null, currency: 'CNY'),
      ],
    );
    expect(result.isOk, true);
    final agg = result.valueOrNull!;
    // 100 + 10*7.2 = 172
    expect(agg.total, Decimal.parse('172.0'));
    expect(agg.baseCurrency, 'CNY');
    expect(agg.rows.length, 2);
    expect(agg.missingRates, containsAll(['a3', 'a4']));
  });

  test('全部同币种时不调用 PriceProvider', () async {
    final usecase = AggregateAccountValueUseCase(_FakePriceProvider(const {}));
    final result = await usecase(
      baseCurrency: 'USD',
      assets: [
        _asset(id: 'x', marketValue: Decimal.parse('5'), currency: 'USD'),
        _asset(id: 'y', marketValue: Decimal.parse('7.5'), currency: 'usd'),
      ],
    );
    expect(result.valueOrNull!.total, Decimal.parse('12.5'));
    expect(result.valueOrNull!.missingRates, isEmpty);
  });

  test('汇率 <= 0 时跳过折算并记入 missingRates', () async {
    final usecase = AggregateAccountValueUseCase(_FakePriceProvider({
      'USD->CNY': Decimal.zero,
    }));
    final result = await usecase(
      baseCurrency: 'CNY',
      assets: [
        _asset(id: 'a1', marketValue: Decimal.parse('10'), currency: 'USD'),
      ],
    );

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.rows, isEmpty);
    expect(result.valueOrNull!.total, Decimal.zero);
    expect(result.valueOrNull!.missingRates, ['a1']);
  });
}
