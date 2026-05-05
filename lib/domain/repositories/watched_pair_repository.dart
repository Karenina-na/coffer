import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/watched_pair.dart';

abstract interface class WatchedPairRepository {
  Stream<List<WatchedPair>> watchAll();
  Future<List<WatchedPair>> listAll();
  Future<Result<WatchedPair, AppError>> add({
    required String baseCurrency,
    required String quoteCurrency,
  });
  Future<Result<void, AppError>> remove(String pairKey);

  /// 更新一条币对的预警阈值。`null` 表示清除该维度的阈值。
  Future<Result<void, AppError>> updateThresholds({
    required String pairKey,
    required Decimal? thresholdHigh,
    required Decimal? thresholdLow,
    required Decimal? alertChangePct,
  });
}
