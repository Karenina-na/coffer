import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/providers/asset/okx_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _tickerJson({
  String instId = 'BTC-USDT',
  String last = '62800.5',
  String ts = '1749988800000',
}) {
  return jsonEncode({
    'code': '0',
    'data': [
      {
        'instId': instId,
        'last': last,
        'ts': ts,
      },
    ],
  });
}

String _candlesJson({
  List<List<String>>? data,
}) {
  return jsonEncode({
    'code': '0',
    'data': data ??
        [
          ['1749988800000', '62700', '62850', '62600', '62800', '15.2', '950000'],
          ['1749902400000', '62100', '62300', '62000', '62200', '12.1', '750000'],
          ['1749816000000', '61100', '61500', '61000', '61200', '8.5', '520000'],
        ],
  });
}

void main() {
  group('OkxProvider._resolveInstId', () {
    test('BTC → BTC-USDT（现货）', () async {
      late Uri capturedUri;
      final p = OkxProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_tickerJson(), 200);
        }),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['instId'], 'BTC-USDT');
    });

    test('BTC-PERP → BTC-USD-SWAP（永续）', () async {
      late Uri capturedUri;
      final p = OkxProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(
            _tickerJson(instId: 'BTC-USD-SWAP', last: '63100'), 200,
          );
        }),
      );
      final r = await p.fetchLatest('BTC-PERP');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['instId'], 'BTC-USD-SWAP');
    });

    test('ETH-USD → ETH-USDT（剥离 -USD 后缀）', () async {
      late Uri capturedUri;
      final p = OkxProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(
            _tickerJson(instId: 'ETH-USDT', last: '3120'), 200,
          );
        }),
      );
      final r = await p.fetchLatest('ETH-USD');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['instId'], 'ETH-USDT');
    });

    test('SOL → SOL-USDT', () async {
      late Uri capturedUri;
      final p = OkxProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(
            _tickerJson(instId: 'SOL-USDT', last: '158.5'), 200,
          );
        }),
      );
      final r = await p.fetchLatest('SOL');
      expect(r.isOk, isTrue);
      expect(capturedUri.queryParameters['instId'], 'SOL-USDT');
    });

    test('AAPL（股票）→ 到达 OKX 返回 API 错误，不预过滤', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(
          jsonEncode({'code': '51001', 'msg': 'instId not found'}), 200,
        )),
      );
      final r = await p.fetchLatest('AAPL');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });
  });

  group('OkxProvider.fetchLatest', () {
    test('正常返回最新价与时间戳', () async {
      final p = OkxProvider(
        client: MockClient((_) async =>
            http.Response(_tickerJson(last: '62800.5', ts: '1749988800000'), 200)),
      );
      final r = await p.fetchLatest('BTC');
      expect(r.isOk, isTrue);
      final q = r.valueOrNull!;
      expect(q.price.toDouble(), closeTo(62800.5, 0.001));
      expect(q.currency, 'USD');
      expect(q.source, 'okx');
      expect(q.asOfTime.millisecondsSinceEpoch, 1749988800000);
    });

    test('symbol 大小写无关，返回统一大写', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(_tickerJson(), 200)),
      );
      final r = await p.fetchLatest('btc');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.symbol, 'BTC');
    });

    test('OKX 错误码非 0 → NetworkError', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(
          jsonEncode({'code': '51001', 'msg': 'instId not found'}), 200,
        )),
      );
      final r = await p.fetchLatest('DOT');
      expect(r.isErr, isTrue);
      expect((r.errorOrNull as NetworkError).kind, NetworkErrorKind.malformedResponse);
    });

    test('500 → NetworkError serverError', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response('server error', 500)),
      );
      final r = await p.fetchLatest('ETH');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('data 为空 → NotFoundError', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(
          jsonEncode({'code': '0', 'data': []}), 200,
        )),
      );
      final r = await p.fetchLatest('ETH');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('永续合约 ETH-PERP 返回正确价格', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(
          _tickerJson(instId: 'ETH-USD-SWAP', last: '3150.25', ts: '1749988800000'), 200,
        )),
      );
      final r = await p.fetchLatest('ETH-PERP');
      expect(r.isOk, isTrue);
      final q = r.valueOrNull!;
      expect(q.price.toDouble(), closeTo(3150.25, 0.001));
      expect(q.currency, 'USD');
      expect(q.source, 'okx');
    });
  });

  group('OkxProvider.fetchTimeSeries', () {
    final from = DateTime(2025, 6, 14);
    final to = DateTime(2025, 6, 16);

    test('正常返回价格序列（已按时间升序）', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(_candlesJson(), 200)),
      );
      final r = await p.fetchTimeSeries(symbol: 'BTC', from: from, to: to);
      expect(r.isOk, isTrue);
      final series = r.valueOrNull!;
      expect(series.points.length, 3);
      expect(series.currency, 'USD');
      expect(series.source, 'okx');
      // 确认已排序
      for (var i = 1; i < series.points.length; i++) {
        expect(
          series.points[i].t.millisecondsSinceEpoch,
          greaterThan(series.points[i - 1].t.millisecondsSinceEpoch),
        );
      }
      expect(series.points.last.price.toDouble(), closeTo(62800.0, 0.001));
    });

    test('URL 中包含 from/to 时间戳', () async {
      late Uri capturedUri;
      final p = OkxProvider(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response(_candlesJson(), 200);
        }),
      );
      await p.fetchTimeSeries(symbol: 'ETH', from: from, to: to);
      expect(
          capturedUri.queryParameters['after'], '${from.millisecondsSinceEpoch}');
      expect(
          capturedUri.queryParameters['before'], '${to.millisecondsSinceEpoch}');
    });

    test('data 为空数组 → NotFoundError', () async {
      final p = OkxProvider(
        client: MockClient((_) async => http.Response(
          jsonEncode({'code': '0', 'data': []}), 200,
        )),
      );
      final r = await p.fetchTimeSeries(symbol: 'BTC', from: from, to: to);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NotFoundError>());
    });

    test('不支持 symbol → OKX 返回 API 错误', () async {
      var called = false;
      final p = OkxProvider(
        client: MockClient((_) async {
          called = true;
          return http.Response(
            jsonEncode({'code': '51001', 'msg': 'instId not found'}), 200,
          );
        }),
      );
      final r = await p.fetchTimeSeries(symbol: 'AAPL', from: from, to: to);
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
      expect(called, isTrue);
    });
  });
}
