import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/exchange_rate.dart';

abstract interface class ExchangeRateRepository {
  /// 获取货币对最新一条快照。
  Future<Result<ExchangeRate, AppError>> latestFor({
    required String baseCurrency,
    required String quoteCurrency,
  });

  Stream<List<ExchangeRate>> watchAll({int limit = 200});

  /// 监听某币对在 [since] 之后的快照序列（按 asOfTime 升序）。
  Stream<List<ExchangeRate>> watchSeriesForPair({
    required String pairKey,
    required DateTime since,
  });

  /// 查询某币对在 [since] 之后的快照序列（Future，非 Stream，用于一次性查询）。
  Future<List<ExchangeRate>> querySeriesForPair({
    required String pairKey,
    required DateTime since,
  });

  /// 查询某币对在 [date] 当天（按 UTC 日期匹配）最近一条快照。
  /// 主要用于历史价格逐点 FX 换算（Bug 8 修复）。
  /// 若查不到则返回 `null`（调用方自行决定是否回退到 spot rate）。
  Future<ExchangeRate?> queryForDate({
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime date,
  });

  Future<Result<ExchangeRate, AppError>> upsert(ExchangeRate rate);
}

/// 汇率查询抽象，领域层消费此接口而非直接依赖 Repository。
///
/// REALTIME / HOURLY / DAILY 的来源差异由具体实现决定。
abstract interface class PriceProvider {
  /// 返回 1 单位 [baseCurrency] 折算为 [quoteCurrency] 的汇率；同币种返回 1。
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  });
}
