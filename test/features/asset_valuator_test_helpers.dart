import 'package:decimal/decimal.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/domain/providers/asset_price_provider.dart';

AssetQuote mkQuote({
  String symbol = 'X',
  String price = '100',
  String currency = 'USD',
}) =>
    AssetQuote(
      symbol: symbol,
      price: Decimal.parse(price),
      currency: currency,
      asOfTime: DateTime.utc(2025, 1, 1),
      source: 'fake',
    );

class FakeAssetPriceProvider implements AssetPriceProvider {
  FakeAssetPriceProvider({AssetQuote? latest, AssetPriceSeries? series})
      : _latest = latest,
        _series = series;

  AssetQuote? _latest;
  final AssetPriceSeries? _series;

  set latest(AssetQuote? v) => _latest = v;

  int latestCalls = 0;
  int seriesCalls = 0;
  String? lastSymbol;

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    latestCalls++;
    lastSymbol = symbol;
    if (_latest == null) return const Err(UnknownError('no data'));
    return Ok(_latest!);
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    seriesCalls++;
    lastSymbol = symbol;
    if (_series == null) return const Err(UnknownError('no data'));
    return Ok(_series);
  }

  void reset() {
    latestCalls = 0;
    seriesCalls = 0;
    lastSymbol = null;
  }
}
