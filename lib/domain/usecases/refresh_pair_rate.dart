import 'package:uuid/uuid.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/exchange_rate.dart';
import '../entities/exchange_rate_enums.dart';
import '../providers/fx_rate_provider.dart';
import '../repositories/exchange_rate_repository.dart';
import '../utils/pair_key.dart';
import '../valuation/asset_valuator.dart';

class RefreshPairRateResult {
  const RefreshPairRateResult({
    required this.pairKey,
    required this.historyCount,
    required this.latestUpdated,
  });

  final String pairKey;
  final int historyCount;
  final bool latestUpdated;
}

class RefreshPairRateUseCase {
  RefreshPairRateUseCase({
    required ExchangeRateRepository rates,
    required FxRateProvider provider,
    Uuid uuid = const Uuid(),
    DateTime Function() now = DateTime.now,
  })  : _rates = rates,
        _provider = provider,
        _uuid = uuid,
        _now = now;

  final ExchangeRateRepository _rates;
  final FxRateProvider _provider;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Result<RefreshPairRateResult, AppError>> call({
    required String pairKey,
    required SyncWindow window,
  }) async {
    final parsed = _parsePairKey(pairKey);
    if (parsed == null) {
      return Err(ValidationError('非法币对：$pairKey'));
    }
    final base = parsed.$1;
    final quote = parsed.$2;
    final now = _now();
    final range = window.rangeFrom(now);

    final historyRes = await _provider.fetchTimeSeries(
      base: base,
      symbols: [quote],
      from: range.from,
      to: range.to,
    );
    if (historyRes.isErr) return Err(historyRes.errorOrNull!);

    var historyCount = 0;
    final history = historyRes.valueOrNull!;
    for (final day in history.series) {
      final rate = day.value[quote];
      if (rate == null) continue;
      final saved = await _rates.upsert(
        ExchangeRate(
          id: _uuid.v4(),
          pairKey: pairKeyOf(base, quote),
          baseCurrency: base,
          quoteCurrency: quote,
          rate: rate,
          asOfTime: day.key,
          updatedAt: now,
          source: 'frankfurter',
          snapshotType: SnapshotType.daily,
          rawPayload: history.rawPayload,
        ),
      );
      if (saved.isErr) return Err(saved.errorOrNull!);
      historyCount++;
    }

    final latestRes = await _provider.fetchLatest(base: base, symbols: [quote]);
    if (latestRes.isErr) return Err(latestRes.errorOrNull!);
    final latest = latestRes.valueOrNull!;
    final latestRate = latest.rates[quote];
    if (latestRate == null) {
      return Err(UnknownError('Frankfurter 未返回 $quote 的数据'));
    }

    final latestSaved = await _rates.upsert(
      ExchangeRate(
        id: _uuid.v4(),
        pairKey: pairKeyOf(base, quote),
        baseCurrency: base,
        quoteCurrency: quote,
        rate: latestRate,
        asOfTime: latest.date,
        updatedAt: now,
        source: 'frankfurter',
        snapshotType: SnapshotType.daily,
        rawPayload: latest.rawPayload,
      ),
    );
    if (latestSaved.isErr) return Err(latestSaved.errorOrNull!);

    return Ok(
      RefreshPairRateResult(
        pairKey: pairKeyOf(base, quote),
        historyCount: historyCount,
        latestUpdated: true,
      ),
    );
  }

  (String, String)? _parsePairKey(String pairKey) {
    final parts = pairKey.split('/');
    if (parts.length != 2) return null;
    final base = parts[0].trim().toUpperCase();
    final quote = parts[1].trim().toUpperCase();
    if (base.isEmpty || quote.isEmpty || base == quote) return null;
    return (base, quote);
  }
}
