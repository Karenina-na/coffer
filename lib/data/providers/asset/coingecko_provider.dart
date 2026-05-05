import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';
import '../network_error.dart';

/// 基于 CoinGecko 公开 API v3 的加密货币价格源（免 API Key）。
///
/// 支持的 symbol 形式（不区分大小写）：
/// - 标准通用代码：`BTC`、`ETH`、`SOL`、`BNB`、`DOT`、`ADA`、`XRP`、`USDT`…
/// - Yahoo 风格：`BTC-USD`、`ETH-USD`（自动剥离 `-USD` 后缀）
///
/// 端点：
/// - 最新价：`GET /api/v3/simple/price`
/// - 历史序列：`GET /api/v3/coins/{id}/market_chart/range`
///
/// 免费端点限速约 10–30 req/min；本 provider 仅做行情补充，
/// 生产环境高频刷新应使用带 API Key 的 Pro 计划。
class CoinGeckoProvider implements AssetPriceProvider {
  CoinGeckoProvider({http.Client? client})
      : _client = client ?? http.Client();

  static const _host = 'api.coingecko.com';
  static const _timeout = Duration(seconds: 12);
  static const _source = 'coingecko';

  final http.Client _client;

  void dispose() => _client.close();

  // ── symbol → CoinGecko coin ID 映射表 ──────────────────────────
  // CoinGecko 使用小写 slug 而非 ticker；常见加密货币硬编码，其余动态查询。
  static const _symbolToId = <String, String>{
    'btc': 'bitcoin',
    'eth': 'ethereum',
    'bnb': 'binancecoin',
    'sol': 'solana',
    'dot': 'polkadot',
    'ada': 'cardano',
    'xrp': 'ripple',
    'ltc': 'litecoin',
    'bch': 'bitcoin-cash',
    'link': 'chainlink',
    'uni': 'uniswap',
    'matic': 'matic-network',
    'pol': 'matic-network',
    'avax': 'avalanche-2',
    'atom': 'cosmos',
    'near': 'near',
    'apt': 'aptos',
    'arb': 'arbitrum',
    'op': 'optimism',
    'trx': 'tron',
    'doge': 'dogecoin',
    'shib': 'shiba-inu',
    'usdt': 'tether',
    'usdc': 'usd-coin',
    'dai': 'dai',
    'busd': 'binance-usd',
    'xau': 'gold',  // CoinGecko 提供黄金参考价
    'xag': 'silver',
    // 永续合约：剥离 -PERP 后缀后路由到现货
    'btc-perp': 'bitcoin',
    'eth-perp': 'ethereum',
  };

  /// 将用户侧 symbol 转换为 CoinGecko coin ID；返回 null 表示不支持。
  static String? _resolveId(String raw) {
    final s = raw.trim().toLowerCase();
    // 剥离 "-USD"、"-USDT"、"-PERP" 等后缀后再查表
    final stripped = s
        .replaceFirst(RegExp(r'-usd[t]?$'), '')
        .replaceFirst(RegExp(r'-perp$'), '');
    return _symbolToId[stripped] ?? _symbolToId[s];
  }

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    final coinId = _resolveId(symbol);
    if (coinId == null) {
      return Err(NotFoundError('coingecko: unsupported symbol $symbol'));
    }

    final uri = Uri.https(_host, '/api/v3/simple/price', {
      'ids': coinId,
      'vs_currencies': 'usd',
      'include_last_updated_at': 'true',
    });

    try {
      final resp = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (resp.statusCode == 429) {
        return const Err(
          NetworkError(
            'coingecko: rate limited (429) — 免费版每分钟限 30 次请求',
            kind: NetworkErrorKind.serverError,
          ),
        );
      }
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus(_source, resp.statusCode, resp.body));
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>?;
      final coinData = json?[coinId] as Map<String, dynamic>?;
      if (coinData == null) {
        return Err(NotFoundError('coingecko: no data for $coinId'));
      }

      final rawPrice = coinData['usd'];
      if (rawPrice == null) {
        return const Err(
          NetworkError('coingecko: missing usd price', kind: NetworkErrorKind.malformedResponse),
        );
      }
      final price = Decimal.parse(rawPrice.toString());
      final ts = coinData['usd_last_updated_at'] as int?;
      final asOf = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
          : DateTime.now().toUtc();

      return Ok(
        AssetQuote(
          symbol: symbol.toUpperCase(),
          price: price,
          currency: 'USD',
          asOfTime: asOf,
          source: _source,
          rawPayload: resp.body,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException(_source, e));
    }
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final coinId = _resolveId(symbol);
    if (coinId == null) {
      return Err(NotFoundError('coingecko: unsupported symbol $symbol'));
    }

    // CoinGecko market_chart/range 用 Unix 秒时间戳
    final fromTs = from.millisecondsSinceEpoch ~/ 1000;
    final toTs = to.millisecondsSinceEpoch ~/ 1000;

    final uri = Uri.https(
      _host,
      '/api/v3/coins/$coinId/market_chart/range',
      {
        'vs_currency': 'usd',
        'from': '$fromTs',
        'to': '$toTs',
        'precision': '6',
      },
    );

    try {
      final resp = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (resp.statusCode == 429) {
        return const Err(
          NetworkError(
            'coingecko: rate limited (429)',
            kind: NetworkErrorKind.serverError,
          ),
        );
      }
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus(_source, resp.statusCode, resp.body));
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>?;
      final prices = json?['prices'] as List<dynamic>?;
      if (prices == null) {
        return const Err(
          NetworkError('coingecko: missing prices array', kind: NetworkErrorKind.malformedResponse),
        );
      }

      final points = <AssetPricePoint>[];
      for (final entry in prices) {
        final pair = entry as List<dynamic>;
        if (pair.length < 2) continue;
        final ms = (pair[0] as num).toInt();
        final p = pair[1];
        if (p == null) continue;
        points.add(
          AssetPricePoint(
            t: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
            price: Decimal.parse(p.toString()),
            currency: 'USD',
          ),
        );
      }
      if (points.isEmpty) {
        return Err(NotFoundError('coingecko: empty price series for $coinId'));
      }

      return Ok(
        AssetPriceSeries(
          symbol: symbol.toUpperCase(),
          currency: 'USD',
          points: points,
          source: _source,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException(_source, e));
    }
  }
}
