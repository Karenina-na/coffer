import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';

/// 外汇最新快照（一次 `latest` 调用的解析结果）。
///
/// 端点约定以 Frankfurter 为参考：
/// `https://api.frankfurter.dev/v1/latest?base=USD&symbols=CNY,JPY`
/// 返回：`{ "amount":1.0, "base":"USD", "date":"YYYY-MM-DD", "rates":{...} }`。
class FxSnapshot {
  const FxSnapshot({
    required this.base,
    required this.date,
    required this.rates,
    required this.rawPayload,
  });

  final String base;
  final DateTime date;
  final Map<String, Decimal> rates;
  final String rawPayload;
}

/// 外汇时间序列：多日 × 多币种的矩阵，用于 sparkline / 回溯。
class FxTimeSeries {
  const FxTimeSeries({
    required this.base,
    required this.series,
    required this.rawPayload,
  });

  final String base;

  /// `Map<date, Map<symbol, rate>>`，按日期升序。
  final List<MapEntry<DateTime, Map<String, Decimal>>> series;
  final String rawPayload;
}

/// 外汇数据源抽象接口。
///
/// domain / usecase 层依赖此接口；data 层提供具体实现（如 Frankfurter）。
abstract interface class FxRateProvider {
  Future<Result<FxSnapshot, AppError>> fetchLatest({
    required String base,
    required List<String> symbols,
  });

  /// 拉取 [from] → [to] 之间的时间序列（含边界）。
  Future<Result<FxTimeSeries, AppError>> fetchTimeSeries({
    required String base,
    required List<String> symbols,
    required DateTime from,
    required DateTime to,
  });
}
