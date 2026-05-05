import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../../domain/utils/pair_key.dart';
import '../db/daos/exchange_rate_dao.dart';
import '../db/daos/exchange_rate_mapper.dart';

class DriftExchangeRateRepository
    implements ExchangeRateRepository, PriceProvider {
  DriftExchangeRateRepository(
    this._dao, {
    ExchangeRateMapper mapper = const ExchangeRateMapper(),
  }) : _mapper = mapper;

  final ExchangeRateDao _dao;
  final ExchangeRateMapper _mapper;

  @override
  Stream<List<ExchangeRate>> watchAll({int limit = 200}) => _dao
      .watchAll(limit: limit)
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<List<ExchangeRate>> watchSeriesForPair({
    required String pairKey,
    required DateTime since,
  }) =>
      _dao
          .watchSeriesForPair(pairKey: pairKey, since: since)
          .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Future<List<ExchangeRate>> querySeriesForPair({
    required String pairKey,
    required DateTime since,
  }) async {
    final rows = await _dao.watchSeriesForPair(pairKey: pairKey, since: since).first;
    return rows.map(_mapper.toDomain).toList(growable: false);
  }

  @override
  Future<ExchangeRate?> queryForDate({
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime date,
  }) async {
    final row = await _dao.queryForDate(
      pairKeyOf(baseCurrency, quoteCurrency),
      date,
    );
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<Result<ExchangeRate, AppError>> latestFor({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    try {
      final row = await _dao.latestForPair(
          pairKeyOf(baseCurrency, quoteCurrency));
      if (row == null) {
        return Err(
          NotFoundError('no rate for $baseCurrency/$quoteCurrency'),
        );
      }
      return Ok(_mapper.toDomain(row));
    } catch (e) {
      return Err(StorageError('latestFor failed: $e'));
    }
  }

  @override
  Future<Result<ExchangeRate, AppError>> upsert(ExchangeRate rate) async {
    try {
      await _dao.upsert(_mapper.toInsert(rate));
      return Ok(rate);
    } catch (e) {
      return Err(StorageError('upsert failed: $e'));
    }
  }

  @override
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    if (baseCurrency.toUpperCase() == quoteCurrency.toUpperCase()) {
      return Ok(Decimal.one);
    }
    final r = await latestFor(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
    );
    return r.when(
      ok: (rate) => Ok(rate.rate),
      err: Err.new,
    );
  }
}
