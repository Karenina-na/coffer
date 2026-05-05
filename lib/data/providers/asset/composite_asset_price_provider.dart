import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';

/// 按顺序尝试多个 [AssetPriceProvider]，返回第一个成功结果。
///
/// 内置熔断：单个 provider 连续失败 5 次后跳过 5 分钟，避免死 provider 拖慢响应。
class CompositeAssetPriceProvider implements AssetPriceProvider {
  CompositeAssetPriceProvider(this._providers, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now());

  final List<AssetPriceProvider> _providers;
  final DateTime Function() _clock;

  // Separate breaker maps for fetchLatest and fetchTimeSeries so that
  // timeseries failures don't trip the latest-price circuit breaker (Bug 16).
  final Map<AssetPriceProvider, _Breaker> _latestBreakers = {};
  final Map<AssetPriceProvider, _Breaker> _seriesBreakers = {};
  static const _failureThreshold = 5;
  static const _coolDown = Duration(minutes: 5);

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    if (_providers.isEmpty) {
      return const Err(UnknownError('no asset price provider configured'));
    }
    final errs = <String>[];
    for (final p in _providers) {
      if (_isOpen(p, _latestBreakers)) continue;
      final r = await p.fetchLatest(symbol);
      if (r.isOk) {
        _resetBreaker(p, _latestBreakers);
        return r;
      }
      _recordFailure(p, _latestBreakers);
      errs.add('${p.runtimeType}: ${r.errorOrNull!.message}');
    }
    return Err(UnknownError('all providers failed: ${errs.join(' | ')}'));
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    if (_providers.isEmpty) {
      return const Err(UnknownError('no asset price provider configured'));
    }
    final errs = <String>[];
    for (final p in _providers) {
      if (_isOpen(p, _seriesBreakers)) continue;
      final r = await p.fetchTimeSeries(symbol: symbol, from: from, to: to);
      if (r.isOk) {
        _resetBreaker(p, _seriesBreakers);
        return r;
      }
      _recordFailure(p, _seriesBreakers);
      errs.add('${p.runtimeType}: ${r.errorOrNull!.message}');
    }
    return Err(UnknownError('all providers failed: ${errs.join(' | ')}'));
  }

  bool _isOpen(AssetPriceProvider p, Map<AssetPriceProvider, _Breaker> breakers) {
    final b = breakers[p];
    if (b == null) return false;
    final delta = _clock().difference(b.firstFailure);
    if (delta.compareTo(_coolDown) >= 0) {
      breakers.remove(p);
      return false;
    }
    return b.failures >= _failureThreshold;
  }

  void _recordFailure(AssetPriceProvider p, Map<AssetPriceProvider, _Breaker> breakers) {
    final b = breakers[p];
    final now = _clock();
    if (b == null) {
      breakers[p] = _Breaker(1, now);
      return;
    }
    if (now.difference(b.firstFailure).compareTo(_coolDown) >= 0) {
      b.failures = 1;
      b.firstFailure = now;
      return;
    }
    b.failures++;
  }

  void _resetBreaker(AssetPriceProvider p, Map<AssetPriceProvider, _Breaker> breakers) {
    final b = breakers[p];
    if (b != null) {
      b.failures = 0;
    }
  }
}

class _Breaker {
  _Breaker(this.failures, this.firstFailure);
  int failures;
  DateTime firstFailure;
}
