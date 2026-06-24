import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/providers/asset/fund_nav_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── 响应构造助手 ──────────────────────────────────────────────

/// 大陆基金 JSONP 响应
String _cnFundJsonp({
  String code = '110011',
  String name = 'EFund Mix',
  String dwjz = '3.8521',
  String? gsz,
  String? gzTime,
}) {
  // 使用 latin1 安全字符串，避免编码问题
  final data = {
    'fundcode': code,
    'name': name,
    'dwjz': dwjz,
    'gsz': gsz ?? dwjz,
    'gszzl': '-0.32',
    'gztime': gzTime ?? '2024-01-15 15:00',
  };
  return 'jsonpgz(${jsonEncode(data)})';
}

/// Yahoo Finance chart 响应
String _yahooChartJson({
  double price = 100.0,
  String currency = 'USD',
  List<int>? timestamps,
  List<double>? closes,
}) {
  final ts = timestamps ?? [1749988800];
  final cl = closes ?? [price];
  return jsonEncode({
    'chart': {
      'result': [
        {
          'meta': {
            'regularMarketPrice': price,
            'currency': currency,
            'regularMarketTime': ts.first,
          },
          'timestamp': ts,
          'indicators': {
            'quote': [
              {'close': cl},
            ],
          },
        },
      ],
    },
  });
}

/// 东方财富基金历史 K 线响应
String _eastmoneyFundKlineJson({
  List<String>? klines,
}) {
  return jsonEncode({
    'data': {
      'klines': klines ??
          [
            '2024-01-12,1.0000,3.8200,3.8200,3.8000,0',
            '2024-01-15,1.0000,3.8521,3.8521,3.8200,0',
          ],
    },
  });
}

void main() {
  group('FundNavProvider.looksLikeFund', () {
    test('大陆基金代码返回 true', () {
      expect(FundNavProvider.looksLikeFund('110011'), isTrue);
      expect(FundNavProvider.looksLikeFund('161725'), isTrue);
      expect(FundNavProvider.looksLikeFund('000001'), isFalse); // 深市股票
      expect(FundNavProvider.looksLikeFund('600519'), isFalse); // 沪市股票
      expect(FundNavProvider.looksLikeFund('300750'), isFalse); // 创业板
    });

    test('香港基金返回 true', () {
      expect(FundNavProvider.looksLikeFund('0001.HK'), isTrue);
      expect(FundNavProvider.looksLikeFund('00001.HK'), isTrue);
    });
  });

  group('FundNavProvider.fetchLatest', () {
    test('大陆基金：解析 JSONP 返回 NAV', () async {
      late Uri capturedUri;
      final p = FundNavProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_cnFundJsonp(), 200);
        }),
      );
      final r = await p.fetchLatest('110011');
      expect(r.isOk, isTrue, reason: 'error: ${r.errorOrNull}');
      final q = r.valueOrNull!;
      expect(q.symbol, '110011');
      expect(q.price.toString(), '3.8521');
      expect(q.currency, 'CNY');
      expect(q.source, 'fund');
      expect(capturedUri.host, 'fundgz.1702502d.com');
    });

    test('大陆基金：空响应返回错误', () async {
      final p = FundNavProvider(
        client: MockClient((req) async => http.Response('', 200)),
      );
      final r = await p.fetchLatest('110011');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('大陆基金：HTTP 错误返回 NetworkError', () async {
      final p = FundNavProvider(
        client: MockClient(
            (req) async => http.Response('server error', 500)),
      );
      final r = await p.fetchLatest('110011');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('香港基金：通过 Yahoo Finance 获取', () async {
      late Uri capturedUri;
      final p = FundNavProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(
            _yahooChartJson(price: 25.5, currency: 'HKD'),
            200,
          );
        }),
      );
      final r = await p.fetchLatest('0001.HK');
      expect(r.isOk, isTrue);
      final q = r.valueOrNull!;
      expect(q.symbol, '0001.HK');
      expect(q.price.toString(), '25.5');
      expect(q.currency, 'HKD');
      expect(capturedUri.host, 'query1.finance.yahoo.com');
    });

    test('非基金代码返回 NotFoundError（不发请求）', () async {
      var requestMade = false;
      final p = FundNavProvider(
        client: MockClient((req) async {
          requestMade = true;
          return http.Response('{}', 200);
        }),
      );
      final r = await p.fetchLatest('AAPL');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
      expect(requestMade, isFalse);
    });

    test('沪深股票代码返回 NotFoundError（不发请求）', () async {
      var requestMade = false;
      final p = FundNavProvider(
        client: MockClient((req) async {
          requestMade = true;
          return http.Response('{}', 200);
        }),
      );
      // 沪市股票
      expect((await p.fetchLatest('600519')).isErr, isTrue);
      // 深市股票
      expect((await p.fetchLatest('000001')).isErr, isTrue);
      // 创业板
      expect((await p.fetchLatest('300750')).isErr, isTrue);
      expect(requestMade, isFalse);
    });
  });

  group('FundNavProvider.fetchTimeSeries', () {
    test('大陆基金：解析 K 线历史', () async {
      final p = FundNavProvider(
        client: MockClient((req) async {
          return http.Response(_eastmoneyFundKlineJson(), 200);
        }),
      );
      final from = DateTime.utc(2024, 1, 1);
      final to = DateTime.utc(2024, 1, 31);
      final r = await p.fetchTimeSeries(
        symbol: '110011',
        from: from,
        to: to,
      );
      expect(r.isOk, isTrue, reason: 'error: ${r.errorOrNull}');
      final series = r.valueOrNull!;
      expect(series.symbol, '110011');
      expect(series.currency, 'CNY');
      expect(series.points.length, 2);
      expect(series.points.first.price.toString(), '3.82');
      expect(series.points.last.price.toString(), '3.8521');
    });

    test('香港基金：通过 Yahoo Finance 获取历史', () async {
      final p = FundNavProvider(
        client: MockClient((req) async {
          return http.Response(
            _yahooChartJson(
              price: 25.5,
              currency: 'HKD',
              timestamps: [1749902400, 1749988800],
              closes: [25.0, 25.5],
            ),
            200,
          );
        }),
      );
      final from = DateTime.utc(2024, 1, 1);
      final to = DateTime.utc(2024, 1, 31);
      final r = await p.fetchTimeSeries(
        symbol: '0001.HK',
        from: from,
        to: to,
      );
      expect(r.isOk, isTrue);
      final series = r.valueOrNull!;
      expect(series.points.length, 2);
    });

    test('非基金代码返回错误', () async {
      final p = FundNavProvider(
        client: MockClient((req) async => http.Response('{}', 200)),
      );
      final r = await p.fetchTimeSeries(
        symbol: 'AAPL',
        from: DateTime.utc(2024, 1, 1),
        to: DateTime.utc(2024, 1, 31),
      );
      expect(r.isErr, isTrue);
    });
  });
}
