import 'package:uuid/uuid.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/exchange_rate.dart';
import '../entities/exchange_rate_enums.dart';
import '../entities/watched_pair.dart';
import '../providers/fx_rate_provider.dart';
import '../repositories/exchange_rate_repository.dart';
import '../repositories/watched_pair_repository.dart';
import '../utils/pair_key.dart';
import '../valuation/asset_valuator.dart';

class RefreshRatesResult {
  const RefreshRatesResult({
    required this.fetched,
    required this.failed,
  });

  /// 成功写入的 `pairKey` 列表。
  final List<String> fetched;

  /// 拉取失败的 `pairKey` → 错误信息。
  final Map<String, String> failed;
}

/// 读取所有 WatchedPair，分组按 base 调用 Frankfurter 批量拉取，
/// 每个成功的币对写入 exchange_rates 表。
///
/// 支持两种同步模式：
/// - [SyncMode.incremental]：仅拉取当天最新汇率（`fetchLatest`），数据量最小。
/// - [SyncMode.full]：拉取最近 8 天的时间序列（`fetchTimeSeries`），用于 sparkline。
class RefreshWatchedRatesUseCase {
  RefreshWatchedRatesUseCase({
    required WatchedPairRepository watchedRepo,
    required ExchangeRateRepository rateRepo,
    required FxRateProvider provider,
    Uuid uuid = const Uuid(),
    DateTime Function() now = DateTime.now,
  })  : _watched = watchedRepo,
        _rates = rateRepo,
        _provider = provider,
        _uuid = uuid,
        _now = now;

  final WatchedPairRepository _watched;
  final ExchangeRateRepository _rates;
  final FxRateProvider _provider;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Result<RefreshRatesResult, AppError>> call({
    SyncMode mode = SyncMode.full,
  }) async {
    final List<WatchedPair> pairs;
    try {
      pairs = await _watched.listAll();
    } catch (e) {
      return Err(StorageError('读取关注币对失败: $e'));
    }
    if (pairs.isEmpty) {
      return const Ok(RefreshRatesResult(fetched: [], failed: {}));
    }

    // 按 base 分组，减少 HTTP 调用次数。
    final groups = <String, List<String>>{};
    for (final p in pairs) {
      groups.putIfAbsent(p.baseCurrency, () => []).add(p.quoteCurrency);
    }

    final fetched = <String>[];
    final failed = <String, String>{};
    final now = _now();

    if (mode == SyncMode.incremental) {
      // 增量：只拉当天最新汇率。
      for (final entry in groups.entries) {
        final base = entry.key;
        final quotes = entry.value;
        final snap = await _provider.fetchLatest(base: base, symbols: quotes);
        await snap.when(
          ok: (s) async {
            for (final q in quotes) {
              final key = pairKeyOf(base, q);
              final rate = s.rates[q];
              if (rate == null) {
                failed[key] = 'Frankfurter 未返回 $q 的数据';
                continue;
              }
              final entity = ExchangeRate(
                id: _uuid.v4(),
                pairKey: key,
                baseCurrency: base,
                quoteCurrency: q,
                rate: rate,
                asOfTime: s.date,
                updatedAt: now,
                source: 'frankfurter',
                snapshotType: SnapshotType.daily,
                rawPayload: s.rawPayload,
              );
              final r = await _rates.upsert(entity);
              r.when(
                ok: (_) => fetched.add(key),
                err: (e) => failed[key] = e.message,
              );
            }
          },
          err: (e) async {
            for (final q in quotes) {
              failed[pairKeyOf(base, q)] = e.message;
            }
          },
        );
      }
    } else {
      // 全量：拉取最近 8 天的日序列：覆盖周末 + 节假日，保证 sparkline 有多点。
      final to = DateTime(now.year, now.month, now.day);
      final from = to.subtract(const Duration(days: 8));

      for (final entry in groups.entries) {
        final base = entry.key;
        final quotes = entry.value;
        final snap = await _provider.fetchTimeSeries(
          base: base,
          symbols: quotes,
          from: from,
          to: to,
        );
        await snap.when(
          ok: (ts) async {
            // 先按 pair 聚合所有天的快照，批量 upsert。
            for (final q in quotes) {
              final key = pairKeyOf(base, q);
              var count = 0;
              for (final day in ts.series) {
                final rate = day.value[q];
                if (rate == null) continue;
                final entity = ExchangeRate(
                  id: _uuid.v4(),
                  pairKey: key,
                  baseCurrency: base,
                  quoteCurrency: q,
                  rate: rate,
                  asOfTime: day.key,
                  updatedAt: now,
                  source: 'frankfurter',
                  snapshotType: SnapshotType.daily,
                  rawPayload: null,
                );
                final r = await _rates.upsert(entity);
                r.when(
                  ok: (_) => count++,
                  err: (e) => failed[key] = e.message,
                );
              }
              if (count > 0) {
                fetched.add(key);
              } else if (!failed.containsKey(key)) {
                failed[key] = 'Frankfurter 未返回 $q 的数据';
              }
            }
          },
          err: (e) async {
            for (final q in quotes) {
              failed[pairKeyOf(base, q)] = e.message;
            }
          },
        );
      }
    }

    return Ok(RefreshRatesResult(fetched: fetched, failed: failed));
  }
}
