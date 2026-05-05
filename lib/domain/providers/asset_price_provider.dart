import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';

/// 单个资产的最新报价。
class AssetQuote {
  const AssetQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    required this.asOfTime,
    required this.source,
    this.rawPayload,
  });

  /// 外部数据源使用的标准代码，例如 `AAPL`、`0700.HK`、`BTC-USD`。
  final String symbol;
  final Decimal price;

  /// 报价币种；可能与资产本币不同，需要上层做汇率换算。
  final String currency;
  final DateTime asOfTime;

  /// 数据源标识，例如 `yahoo`。
  final String source;
  final String? rawPayload;
}

/// 时间序列上的一个价格点。
class AssetPricePoint {
  const AssetPricePoint({
    required this.t,
    required this.price,
    required this.currency,
  });

  final DateTime t;
  final Decimal price;
  final String currency;
}

/// 多点历史序列响应。
class AssetPriceSeries {
  const AssetPriceSeries({
    required this.symbol,
    required this.currency,
    required this.points,
    required this.source,
  });

  final String symbol;
  final String currency;
  final List<AssetPricePoint> points;
  final String source;
}

/// 资产价格外部数据源的抽象接口。
///
/// 实现放在 data 层（Yahoo / 东方财富 / Composite）；domain / usecase
/// 只依赖此接口，便于测试与替换数据源。
abstract interface class AssetPriceProvider {
  /// 拉取指定资产代码的最新报价。
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol);

  /// 拉取 [symbol] 在 [from, to] 区间（含边界）的日频历史序列。
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  });
}
