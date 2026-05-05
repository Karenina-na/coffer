import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/providers/asset/coingecko_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── 响应构造助手 ──────────────────────────────────────────────

String _priceJson({
  String coinId = 'bitcoin',
  double? price = 62800.0,
  int? lastUpdated,
}) {
  final ts = lastUpdated ?? 1749988800;
  return jsonEncode({
    coinId: {
      'usd': price,
      'usd_last_updated_at': ts,
    },
  });
}

String _seriesJson({
  List<List<dynamic>>? prices,
}) {
  return jsonEncode({
    'prices': prices ??
        [
          [1749816000000, 61200.5],
          [1749902400000, 62100.0],
          [1749988800000, 62800.0],
        ],
  });
}

void main() {
  group('CoinGeckoProvider._resolveId', () {
    // 通过 fetchLatest 间接验证路由，404 等错误证明 ID 已被正确解析

    test('BTC → bitcoin', () async {
      late Uri capturedUri;
      final p = CoinGeckoProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_priceJson(coinId: 'bitcoin'), 200);
        }),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['ids'], 'bitcoin');
    });

    test('eth-usd → ethereum（剥离 -USD 后缀）', () async {
      late Uri capturedUri;
      final p = CoinGeckoProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_priceJson(coinId: 'ethereum'), 200);
        }),
      );
      final r = await p.fetchLatest('ETH-USD');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['ids'], 'ethereum');
    });

    test('BTC-PERP → bitcoin（剥离 -PERP 后缀）', () async {
      late Uri capturedUri;
      final p = CoinGeckoProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_priceJson(coinId: 'bitcoin'), 200);
        }),
      );
      final r = await p.fetchLatest('BTC-PERP');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['ids'], 'bitcoin');
    });

    test('SOL → solana', () async {
      late Uri capturedUri;
      final p = CoinGeckoProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_priceJson(coinId: 'solana', price: 158.5), 200);
        }),
      );
      final r = await p.fetchLatest('SOL');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['ids'], 'solana');
    });

    test('AAPL（股票）→ NotFoundError（不支持）', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final r = await p.fetchLatest('AAPL');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });
  });

  group('CoinGeckoProvider.fetchLatest', () {
    test('正常返回最新价与时间戳', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async =>
            http.Response(_priceJson(price: 62800.0, lastUpdated: 1749988800), 200)),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isOk, isTrue);
      final q = r.valueOrNull!;
      expect(q.price.toDouble(), closeTo(62800.0, 0.001));
      expect(q.currency, 'USD');
      expect(q.source, 'coingecko');
      expect(q.asOfTime.millisecondsSinceEpoch, 1749988800 * 1000);
    });

    test('symbol 大小写无关，返回统一大写', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response(_priceJson(), 200)),
      );
      final r = await p.fetchLatest('btc');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.symbol, 'BTC');
    });

    test('429 → NetworkError serverError', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response('rate limit', 429)),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isErr, isTrue);
      expect((r.errorOrNull as NetworkError).kind, NetworkErrorKind.serverError);
    });

    test('缺少 usd 字段 → malformedResponse', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response(
          jsonEncode({'bitcoin': {'usd_last_updated_at': 1749988800}}), 200,
        )),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isErr, isTrue);
      expect((r.errorOrNull as NetworkError).kind, NetworkErrorKind.malformedResponse);
    });

    test('coinId 不在响应 JSON 中 → NotFoundError', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      // ethereum 路由到 'ethereum'，但响应体为空对象
      final r = await p.fetchLatest('ETH');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('500 → NetworkError serverError', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response('server error', 500)),
      );
      final r = await p.fetchLatest('ETH');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });
  });

  group('CoinGeckoProvider.fetchTimeSeries', () {
    final from = DateTime(2025, 6, 14);
    final to = DateTime(2025, 6, 16);

    test('正常返回价格序列', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response(_seriesJson(), 200)),
      );
      final r = await p.fetchTimeSeries(symbol: 'BTC', from: from, to: to);
      expect(r.isOk, isTrue);
      final series = r.valueOrNull!;
      expect(series.points.length, 3);
      expect(series.currency, 'USD');
      expect(series.source, 'coingecko');
      expect(series.points.last.price.toDouble(), closeTo(62800.0, 0.001));
    });

    test('URL 中 from/to 为 Unix 秒', () async {
      late Uri capturedUri;
      final p = CoinGeckoProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_seriesJson(), 200);
        }),
      );
      await p.fetchTimeSeries(symbol: 'ETH', from: from, to: to);
      expect(capturedUri.queryParameters['from'],
          '${from.millisecondsSinceEpoch ~/ 1000}');
      expect(capturedUri.queryParameters['to'],
          '${to.millisecondsSinceEpoch ~/ 1000}');
    });

    test('prices 数组为空 → NotFoundError', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async =>
            http.Response(jsonEncode({'prices': []}), 200)),
      );
      final r = await p.fetchTimeSeries(symbol: 'BTC', from: from, to: to);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('响应缺少 prices 字段 → malformedResponse', () async {
      final p = CoinGeckoProvider(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final r = await p.fetchTimeSeries(symbol: 'BTC', from: from, to: to);
      expect(r.isErr, isTrue);
      expect((r.errorOrNull as NetworkError).kind, NetworkErrorKind.malformedResponse);
    });

    test('不支持 symbol → NotFoundError（不发网络请求）', () async {
      var called = false;
      final p = CoinGeckoProvider(
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      final r = await p.fetchTimeSeries(symbol: 'AAPL', from: from, to: to);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
      expect(called, isFalse);
    });
  });
}
