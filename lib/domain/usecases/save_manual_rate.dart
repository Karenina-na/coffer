import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/dict_type.dart';
import '../entities/exchange_rate.dart';
import '../entities/exchange_rate_enums.dart';
import '../repositories/dict_repository.dart';
import '../repositories/exchange_rate_repository.dart';
import '../utils/pair_key.dart';
import 'manage_watched_pair.dart';

class SaveManualRateUseCase {
  SaveManualRateUseCase({
    required ExchangeRateRepository rates,
    required ManageWatchedPairUseCase watchedPairs,
    required DictRepository dicts,
    required String Function() idGenerator,
    required DateTime Function() now,
  })  : _rates = rates,
        _watchedPairs = watchedPairs,
        _dicts = dicts,
        _idGen = idGenerator,
        _now = now;

  final ExchangeRateRepository _rates;
  final ManageWatchedPairUseCase _watchedPairs;
  final DictRepository _dicts;
  final String Function() _idGen;
  final DateTime Function() _now;

  Future<Result<ExchangeRate, AppError>> call({
    required String baseCurrency,
    required String quoteCurrency,
    required Decimal rate,
    required SnapshotType snapshotType,
    String source = 'manual',
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final quote = quoteCurrency.trim().toUpperCase();
    final normalizedSource = source.trim().isEmpty ? 'manual' : source.trim();
    if (base.isEmpty || quote.isEmpty) {
      return const Err(ValidationError('币种不能为空'));
    }
    final baseEntry = await _dicts.findByTypeAndCode(DictType.currency, base);
    if (baseEntry == null) {
      return Err(ValidationError('未知币种：$base'));
    }
    final quoteEntry = await _dicts.findByTypeAndCode(DictType.currency, quote);
    if (quoteEntry == null) {
      return Err(ValidationError('未知币种：$quote'));
    }
    if (base == quote) {
      return const Err(ValidationError('基准与报价不能相同'));
    }
    if (rate <= Decimal.zero) {
      return const Err(ValidationError('汇率必须大于 0'));
    }
    final now = _now();
    final entity = ExchangeRate(
      id: _idGen(),
      pairKey: pairKeyOf(base, quote),
      baseCurrency: base,
      quoteCurrency: quote,
      rate: rate,
      asOfTime: now,
      updatedAt: now,
      source: normalizedSource,
      snapshotType: snapshotType,
    );
    final saved = await _rates.upsert(entity);
    if (saved.isErr) return Err(saved.errorOrNull!);
    final watched = await _watchedPairs.add(baseCurrency: base, quoteCurrency: quote);
    if (watched.isErr) {
      return Err(watched.errorOrNull!);
    }
    return saved;
  }
}
