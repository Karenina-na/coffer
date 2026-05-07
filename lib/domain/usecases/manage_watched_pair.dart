import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/dict_type.dart';
import '../entities/watched_pair.dart';
import '../repositories/dict_repository.dart';
import '../repositories/watched_pair_repository.dart';

class ManageWatchedPairUseCase {
  const ManageWatchedPairUseCase(this._repo, this._dicts);

  final WatchedPairRepository _repo;
  final DictRepository _dicts;

  Future<Result<WatchedPair, AppError>> add({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final quote = quoteCurrency.trim().toUpperCase();
    if (base.isEmpty || quote.isEmpty) {
      return Future.value(const Err(ValidationError('币种不能为空')));
    }
    if (base == quote) {
      return Future.value(const Err(ValidationError('基准与报价不能相同')));
    }
    final baseEntry = await _dicts.findByTypeAndCode(DictType.currency, base);
    if (baseEntry == null) {
      return Err(ValidationError('未知币种：$base'));
    }
    final quoteEntry = await _dicts.findByTypeAndCode(DictType.currency, quote);
    if (quoteEntry == null) {
      return Err(ValidationError('未知币种：$quote'));
    }
    return _repo.add(baseCurrency: base, quoteCurrency: quote);
  }

  Future<Result<void, AppError>> remove(String pairKey) {
    if (pairKey.trim().isEmpty) {
      return Future.value(const Err(ValidationError('pairKey 不能为空')));
    }
    return _repo.remove(pairKey.trim().toUpperCase());
  }

  Future<Result<void, AppError>> updateThresholds({
    required String pairKey,
    required Decimal? thresholdHigh,
    required Decimal? thresholdLow,
    required Decimal? alertChangePct,
  }) {
    if (pairKey.trim().isEmpty) {
      return Future.value(const Err(ValidationError('pairKey 不能为空')));
    }
    if (thresholdHigh != null && thresholdLow != null && thresholdLow >= thresholdHigh) {
      return Future.value(const Err(ValidationError('下沿必须小于上沿')));
    }
    if (alertChangePct != null && alertChangePct <= Decimal.zero) {
      return Future.value(const Err(ValidationError('波动幅度阈值必须为正数')));
    }
    return _repo.updateThresholds(
      pairKey: pairKey.trim().toUpperCase(),
      thresholdHigh: thresholdHigh,
      thresholdLow: thresholdLow,
      alertChangePct: alertChangePct,
    );
  }
}
