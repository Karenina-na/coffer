import 'package:decimal/decimal.dart';

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/repositories/exchange_rate_repository.dart';
import 'frankfurter_provider.dart';

/// PriceProvider 组合：本地 DB → 反向换算 → 远端 Frankfurter 兜底。
///
/// 解决 `RefreshAssetPriceUseCase` / `ValuateAssetUseCase` 在做币种换算时，
/// 若用户还未手动同步对应币对就会直接 `NotFoundError('no rate for X/Y')` 的问题。
///
/// 查找顺序：
/// 1. 本地直接匹配 `BASE/QUOTE`
/// 2. 本地反向匹配 `QUOTE/BASE`，取倒数
/// 3. 远端 Frankfurter 实时抓取（不写回 DB，避免与用户的 watched 列表耦合）
class CachedFxPriceProvider implements PriceProvider {
  CachedFxPriceProvider({
    required PriceProvider local,
    required FrankfurterProvider remote,
    DateTime Function()? clock,
    Duration remoteCacheTtl = const Duration(minutes: 5),
    Duration failureCooldown = const Duration(minutes: 10),
  }) : _local = local,
       _remote = remote,
       _clock = clock ?? DateTime.now,
       _remoteCacheTtl = remoteCacheTtl,
       _failureCooldown = failureCooldown;

  final PriceProvider _local;
  final FrankfurterProvider _remote;
  final DateTime Function() _clock;
  final Duration _remoteCacheTtl;
  final Duration _failureCooldown;
  final Map<String, _FxCacheEntry> _remoteCache = {};
  // in-flight futures to avoid duplicate concurrent remote requests for the same pair.
  final Map<String, Future<Result<Decimal, AppError>>> _inflight = {};
  // negative cache: pairs that recently failed, storing the expiry time.
  final Map<String, DateTime> _failureExpiry = {};

  /// `1 / r` 的小数保留精度。12 位对法币 / 主流加密均足够。
  static const _inverseScale = 12;

  @override
  Future<Result<Decimal, AppError>> getRate({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    final b = baseCurrency.trim().toUpperCase();
    final q = quoteCurrency.trim().toUpperCase();
    if (b.isEmpty || q.isEmpty) {
      return const Err(ValidationError('empty currency code'));
    }
    if (b == q) return Ok(Decimal.one);

    // 1) 本地直接
    final direct = await _local.getRate(baseCurrency: b, quoteCurrency: q);
    if (direct.isOk) return direct;

    // 2) 本地反向
    final inverse = await _local.getRate(baseCurrency: q, quoteCurrency: b);
    if (inverse.isOk) {
      final r = inverse.valueOrNull!;
      if (r > Decimal.zero) {
        final inv = (Decimal.one / r).toDecimal(
          scaleOnInfinitePrecision: _inverseScale,
        );
        return Ok(inv);
      }
    }

    final cached = _getCachedRate(b, q);
    if (cached != null) return Ok(cached);

    // Check negative cache: skip remote call if this pair recently failed.
    final key = _pairKey(b, q);
    final failExpiry = _failureExpiry[key];
    if (failExpiry != null && _clock().isBefore(failExpiry)) {
      return Err(NotFoundError('no rate for $b/$q (cooldown)'));
    }

    // 3) 远端兜底（Frankfurter 仅支持 ~33 种法币，crypto/商品会失败）
    // 相同 pair 的并发请求复用同一 in-flight Future，避免重复 HTTP 调用。
    return _inflight.putIfAbsent(key, () async {
      try {
        final snap = await _remote.fetchLatest(base: b, symbols: [q]);
        if (snap.isErr) {
          _failureExpiry[key] = _clock().add(_failureCooldown);
          return Err(
            NotFoundError(
              'no rate for $b/$q (local miss, remote: ${snap.errorOrNull!.message})',
            ),
          );
        }
        final rate = snap.valueOrNull!.rates[q];
        if (rate == null) {
          _failureExpiry[key] = _clock().add(_failureCooldown);
          return Err(NotFoundError('no rate for $b/$q'));
        }
        _cacheRatePair(baseCurrency: b, quoteCurrency: q, rate: rate);
        return Ok(rate);
      } finally {
        _inflight.remove(key);
      }
    });
  }

  Decimal? _getCachedRate(String baseCurrency, String quoteCurrency) {
    final entry = _remoteCache[_pairKey(baseCurrency, quoteCurrency)];
    if (entry == null) return null;
    final age = _clock().difference(entry.fetchedAt);
    if (age >= _remoteCacheTtl) {
      _remoteCache.remove(_pairKey(baseCurrency, quoteCurrency));
      return null;
    }
    return entry.rate;
  }

  void _cacheRatePair({
    required String baseCurrency,
    required String quoteCurrency,
    required Decimal rate,
  }) {
    final now = _clock();
    _remoteCache[_pairKey(baseCurrency, quoteCurrency)] = _FxCacheEntry(
      rate,
      now,
    );
    if (rate > Decimal.zero) {
      final inverse = (Decimal.one / rate).toDecimal(
        scaleOnInfinitePrecision: _inverseScale,
      );
      _remoteCache[_pairKey(quoteCurrency, baseCurrency)] = _FxCacheEntry(
        inverse,
        now,
      );
    }
  }

  String _pairKey(String baseCurrency, String quoteCurrency) =>
      '$baseCurrency/$quoteCurrency';
}

class _FxCacheEntry {
  const _FxCacheEntry(this.rate, this.fetchedAt);

  final Decimal rate;
  final DateTime fetchedAt;
}
