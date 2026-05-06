import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../entities/asset.dart';
import '../../entities/asset_enums.dart';
import '../../providers/asset_price_provider.dart';
import '../asset_valuator.dart';

/// 适用于市场行情类资产：股票、基金、加密、贵金属、期货 / 期权 / 合约等。
///
/// 数据来源：注入的 [AssetPriceProvider]（通常为 CompositeAssetPriceProvider，
/// 按顺序尝试 Yahoo / 东方财富 / OKX / 基金净值，内置熔断机制）。
/// 缓存：进程内 TTL，避免短时间内连续刷新打爆远端。
/// - 最新价：`latestTtl` 默认 5 分钟
/// - 历史序列：按 `(symbol, fromDay, toDay)` 粒度缓存 `historyTtl` 默认 6 小时
class MarketQuoteValuator implements AssetValuator {
  MarketQuoteValuator({
    required AssetPriceProvider source,
    DateTime Function()? clock,
    Duration latestTtl = const Duration(minutes: 5),
    Duration historyTtl = const Duration(hours: 6),
  })  : _source = source,
        _clock = clock ?? DateTime.now,
        _latestTtl = latestTtl,
        _historyTtl = historyTtl;

  final AssetPriceProvider _source;
  final DateTime Function() _clock;
  final Duration _latestTtl;
  final Duration _historyTtl;

  static const _supported = <AssetType>{
    AssetType.stock,
    AssetType.fund,
    AssetType.crypto,
    AssetType.perpetual,
    AssetType.contract,
    AssetType.preciousMetal,
    AssetType.future,
    AssetType.option,
    AssetType.warrant,
    AssetType.fxAsset,
  };

  /// 对可做 FX 换算的现金持仓 (fxAsset) 也放行：此时 `symbol` 形如 `USDCNY=X`
  /// 可由 Yahoo 提供；若无对应 symbol 的资产，应配置 ManualValuator 捕获。
  @override
  bool supports(Asset asset) =>
      _supported.contains(asset.assetType) && _symbolFor(asset) != null;

  // —— 缓存 ——

  final Map<String, _LatestEntry> _latestCache = {};
  final Map<String, _SeriesEntry> _seriesCache = {};

  // Prevent unbounded memory growth from unique symbol/date combinations.
  static const _maxLatestEntries = 200;
  static const _maxSeriesEntries = 500;

  void _pruneLatestCache() {
    if (_latestCache.length <= _maxLatestEntries) return;
    final keys = _latestCache.keys.toList();
    keys.sort((a, b) =>
        _latestCache[a]!.fetchedAt.compareTo(_latestCache[b]!.fetchedAt));
    for (var i = 0; i < keys.length - _maxLatestEntries ~/ 2; i++) {
      _latestCache.remove(keys[i]);
    }
  }

  void _pruneSeriesCache() {
    if (_seriesCache.length <= _maxSeriesEntries) return;
    final keys = _seriesCache.keys.toList();
    keys.sort((a, b) =>
        _seriesCache[a]!.fetchedAt.compareTo(_seriesCache[b]!.fetchedAt));
    for (var i = 0; i < keys.length - _maxSeriesEntries ~/ 2; i++) {
      _seriesCache.remove(keys[i]);
    }
  }

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    final symbol = _symbolFor(asset);
    if (symbol == null) {
      return const Err(ValidationError('资产缺少代码（assetCode / priceSymbol）'));
    }
    final now = _clock();
    if (!forceRefresh) {
      final cached = _latestCache[symbol];
      if (cached != null && now.difference(cached.fetchedAt) < _latestTtl) {
        return Ok(cached.quote);
      }
    }
    final r = await _source.fetchLatest(symbol);
    if (r.isOk) {
      _latestCache[symbol] = _LatestEntry(r.valueOrNull!, now);
      _pruneLatestCache();
    }
    return r;
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final symbol = _symbolFor(asset);
    if (symbol == null) {
      return const Err(ValidationError('资产缺少代码（assetCode / priceSymbol）'));
    }
    final key = _seriesKey(symbol, from, to);
    final now = _clock();
    if (!forceRefresh) {
      final cached = _seriesCache[key];
      if (cached != null && now.difference(cached.fetchedAt) < _historyTtl) {
        return Ok(cached.series);
      }
    }
    final r = await _source.fetchTimeSeries(
      symbol: symbol,
      from: from,
      to: to,
    );
    if (r.isOk) {
      _seriesCache[key] = _SeriesEntry(r.valueOrNull!, now);
      _pruneSeriesCache();
    }
    return r;
  }
  /// 清空缓存。用于测试或「强制刷新」入口。
  void invalidate() {
    _latestCache.clear();
    _seriesCache.clear();
  }

  // —— 内部工具 ——

  String? _symbolFor(Asset a) {
    final override = a.extInfo?['priceSymbol'];
    if (override is String && override.trim().isNotEmpty) {
      return override.trim();
    }
    final code = a.assetCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return null;
  }

  String _seriesKey(String symbol, DateTime from, DateTime to) {
    String d(DateTime t) {
      final l = t.toUtc();
      return '${l.year}-${l.month}-${l.day}';
    }

    return '$symbol|${d(from)}|${d(to)}';
  }
}

class _LatestEntry {
  const _LatestEntry(this.quote, this.fetchedAt);
  final AssetQuote quote;
  final DateTime fetchedAt;
}

class _SeriesEntry {
  const _SeriesEntry(this.series, this.fetchedAt);
  final AssetPriceSeries series;
  final DateTime fetchedAt;
}
