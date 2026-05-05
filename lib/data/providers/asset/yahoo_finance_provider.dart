import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';
import '../network_error.dart';

/// 基于 Yahoo Finance 公开 chart 接口的资产价格源。
class YahooFinanceProvider implements AssetPriceProvider {
  YahooFinanceProvider({http.Client? client})
    : _client = client ?? http.Client();

  static const _host = 'query1.finance.yahoo.com';
  static const _basePath = '/v8/finance/chart/';
  static const _timeout = Duration(seconds: 10);
  static const _source = 'yahoo';

  final http.Client _client;

  void dispose() => _client.close();

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));

    final uri = Uri.https(_host, '$_basePath$s', const {
      'interval': '1d',
      'range': '5d',
    });

    try {
      final resp = await _client
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (GWP)'})
          .timeout(_timeout);
      final body = resp.body;
      final contentType = resp.headers['content-type'] ?? '';
      if (contentType.contains('text/html') &&
          (body.contains('中国大陆') || body.contains('G.F.W'))) {
        return const Err(
          NetworkError(
            'yahoo blocked: Yahoo Finance 在中国大陆不可用，请开启 VPN/代理后重试',
            kind: NetworkErrorKind.connectivity,
          ),
        );
      }
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus('yahoo', resp.statusCode, body));
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return const Err(NotFoundError('yahoo: symbol not found'));
      }
      final first = results.first as Map<String, dynamic>;
      final meta = first['meta'] as Map<String, dynamic>?;
      if (meta == null) {
        return Err(
          NetworkError(
            'yahoo malformed: $body',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final price = meta['regularMarketPrice'];
      final ts = meta['regularMarketTime'];
      if (price == null || ts == null) {
        return Err(
          NetworkError(
            'yahoo missing price fields: $body',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final priceStr = price is num ? price.toString() : '$price';
      final parsedPrice = Decimal.tryParse(priceStr);
      if (parsedPrice == null) {
        return Err(
          NetworkError(
            'yahoo: invalid price format: $priceStr',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final currency = _readRequiredCurrency(meta);
      if (currency == null) {
        return Err(
          NetworkError(
            'yahoo malformed: missing or invalid currency',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final asOfTime = DateTime.fromMillisecondsSinceEpoch(
        ((ts is num ? ts.toInt() : int.parse('$ts')) * 1000),
        isUtc: true,
      );
      final assetPrice = AssetQuote(
        symbol: s,
        price: parsedPrice,
        currency: currency,
        asOfTime: asOfTime,
        source: _source,
      );
      return Ok(assetPrice);
    } catch (e) {
      return Err(classifyNetworkException('yahoo', e));
    }
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));

    final fromUnix = from.millisecondsSinceEpoch ~/ 1000;
    final toUnix = to.millisecondsSinceEpoch ~/ 1000 + 86400;

    final uri = Uri.https(_host, '$_basePath$s', {
      'period1': '$fromUnix',
      'period2': '$toUnix',
      'interval': '1d',
    });

    try {
      final resp = await _client
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (GWP)'})
          .timeout(_timeout);
      final body = resp.body;
      final contentType = resp.headers['content-type'] ?? '';
      if (contentType.contains('text/html') &&
          (body.contains('中国大陆') || body.contains('G.F.W'))) {
        return const Err(
          NetworkError(
            'yahoo blocked: Yahoo Finance 在中国大陆不可用，请开启 VPN/代理后重试',
            kind: NetworkErrorKind.connectivity,
          ),
        );
      }
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus('yahoo', resp.statusCode, body));
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return const Err(NotFoundError('yahoo: symbol not found'));
      }
      final first = results.first as Map<String, dynamic>;
      final meta = first['meta'] as Map<String, dynamic>?;
      final timestamps = (first['timestamp'] as List<dynamic>?) ?? const [];
      final indicators = first['indicators'] as Map<String, dynamic>?;
      final quoteArr = indicators?['quote'] as List<dynamic>?;
      final closes = quoteArr != null && quoteArr.isNotEmpty
          ? (quoteArr.first as Map<String, dynamic>)['close'] as List<dynamic>?
          : null;
      if (meta == null || closes == null) {
        return Err(
          NetworkError(
            'yahoo malformed series: $body',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final currency = _readRequiredCurrency(meta);
      if (currency == null) {
        return Err(
          NetworkError(
            'yahoo malformed series: missing or invalid currency',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }

      final points = <AssetPricePoint>[];
      final n = timestamps.length < closes.length
          ? timestamps.length
          : closes.length;
      for (var i = 0; i < n; i++) {
        final ts = (timestamps[i] as num?)?.toInt();
        final close = closes[i];
        if (ts == null || close == null) continue;
        final price = Decimal.tryParse(close.toString());
        if (price == null) continue;
        if (price <= Decimal.zero) {
          return Err(
            NetworkError(
              'yahoo malformed series: non-positive close price',
              kind: NetworkErrorKind.malformedResponse,
            ),
          );
        }
        points.add(
          AssetPricePoint(
            t: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
            price: price,
            currency: currency,
          ),
        );
      }

      if (points.isEmpty) {
        return const Err(NotFoundError('yahoo: no valid price points'));
      }
      return Ok(
        AssetPriceSeries(
          symbol: (meta['symbol'] as String?) ?? s,
          currency: currency,
          points: points,
          source: _source,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException('yahoo-timeseries', e));
    }
  }

  String? _readRequiredCurrency(Map<String, dynamic> meta) {
    final raw = meta['currency'];
    if (raw is! String) return null;
    final currency = raw.trim().toUpperCase();
    if (currency.isEmpty) return null;
    return currency;
  }
}
