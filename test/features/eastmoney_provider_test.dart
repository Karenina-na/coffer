import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/providers/asset/eastmoney_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Helper to build a minimal eastmoney quote JSON response.
String _quoteJson({String? price}) {
  final f43 = price ?? '150.0';
  return jsonEncode({
    'data': {
      'f43': f43,
      'f58': 'TestStock',
      'f59': 2,
      'f60': 149.0,
      'f86': 1749600000,
    },
  });
}

/// Helper to build a minimal eastmoney kline JSON response.
String _klineJson({List<String>? klines}) {
  return jsonEncode({
    'data': {
      'klines':
          klines ??
          [
            '2025-06-14,149.0,150.0,151.0,148.0,1000000',
            '2025-06-15,150.0,151.5,152.0,149.5,1100000',
          ],
    },
  });
}

void main() {
  group('EastmoneyProvider._resolveSecIds (tested via fetchLatest)', () {
    // 1) xx.HK suffix → 116.0xxxx
    test('0700.HK routes to HK exchange with zero-padded secid', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      final r = await provider.fetchLatest('0700.HK');
      expect(r.isOk, isTrue);
      expect(capturedSecid, '116.00700');
    });

    // 2) 600519.SS / 600519.SH → Shanghai
    test('600519.SS routes to Shanghai (prefix 1)', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('600519.SS');
      expect(capturedSecid, '1.600519');
    });

    test('000001.SZ routes to Shenzhen (prefix 0)', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('000001.SZ');
      expect(capturedSecid, '0.000001');
    });

    // 3) pure letter code (1-5 chars) → US market
    test('AAPL (pure letters) routes to US NASDAQ first', () async {
      final capturedSecids = <String>[];
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecids.add(request.url.queryParameters['secid'] ?? '');
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('AAPL');
      expect(capturedSecids.first, '105.AAPL');
    });

    test('AAPL.US routes to US market', () async {
      final capturedSecids = <String>[];
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecids.add(request.url.queryParameters['secid'] ?? '');
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('AAPL.US');
      expect(capturedSecids.first, '105.AAPL');
    });

    // 4) 6-digit code starting with 6 → Shanghai
    test('600519 (6-digit, starts with 6) routes to Shanghai', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('600519');
      expect(capturedSecid, '1.600519');
    });

    // 5) 6-digit code starting with 0 → Shenzhen
    test('000001 (6-digit, starts with 0) routes to Shenzhen', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('000001');
      expect(capturedSecid, '0.000001');
    });

    // 6) 5-digit number → HK (direct, no padding)
    test('00700 (5-digit) routes to HK exchange', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('00700');
      expect(capturedSecid, '116.00700');
    });

    // 7) 4-digit starting with 0 → HK (padded to 5)
    test('0700 (4-digit, starts with 0) routes to HK exchange', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('0700');
      expect(capturedSecid, '116.00700');
    });

    // 8) 4-digit codes (including non-0-starting) → route to HK with zero-padding
    test(
      '1234 (4-digit, non-0-starting) routes to HK stock 01234',
      () async {
        var capturedSecid = '';
        final provider = EastmoneyProvider(
          client: MockClient((request) async {
            capturedSecid = request.url.queryParameters['secid'] ?? '';
            return http.Response(_quoteJson(), 200);
          }),
        );
        final r = await provider.fetchLatest('1234');
        expect(r.isOk, isTrue);
        expect(capturedSecid, '116.01234');
      },
    );

    // 9) direct secid passthrough
    test('116.00700 (direct secid) passes through unchanged', () async {
      var capturedSecid = '';
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          capturedSecid = request.url.queryParameters['secid'] ?? '';
          return http.Response(_quoteJson(), 200);
        }),
      );
      await provider.fetchLatest('116.00700');
      expect(capturedSecid, '116.00700');
    });

    // 10) empty symbol returns ValidationError without HTTP call
    test('empty symbol returns ValidationError', () async {
      var httpCalled = false;
      final provider = EastmoneyProvider(
        client: MockClient((request) async {
          httpCalled = true;
          return http.Response('{}', 200);
        }),
      );
      final r = await provider.fetchLatest('');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<ValidationError>());
      expect(httpCalled, isFalse);
    });
  });

  group('EastmoneyProvider HTTP response handling', () {
    test('successful fetch returns AssetQuote with correct price', () async {
      final provider = EastmoneyProvider(
        client: MockClient(
          (_) async => http.Response(_quoteJson(price: '123.45'), 200),
        ),
      );
      final r = await provider.fetchLatest('AAPL');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.price, Decimal.parse('123.45'));
      expect(r.valueOrNull!.source, 'eastmoney');
    });

    test('HTTP 404 returns NetworkError', () async {
      final provider = EastmoneyProvider(
        client: MockClient((_) async => http.Response('Not Found', 404)),
      );
      final r = await provider.fetchLatest('AAPL');
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('fetchTimeSeries parses kline data into points', () async {
      final provider = EastmoneyProvider(
        client: MockClient((_) async => http.Response(_klineJson(), 200)),
      );
      final r = await provider.fetchTimeSeries(
        symbol: 'AAPL',
        from: DateTime.utc(2025, 6, 14),
        to: DateTime.utc(2025, 6, 15),
      );
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.points.length, 2);
      expect(r.valueOrNull!.points.first.price, Decimal.parse('150.0'));
    });

    test('fetchTimeSeries rejects zero or negative kline close', () async {
      final provider = EastmoneyProvider(
        client: MockClient(
          (_) async => http.Response(
            _klineJson(klines: ['2025-06-14,149.0,0,151.0,148.0,1000000']),
            200,
          ),
        ),
      );
      final r = await provider.fetchTimeSeries(
        symbol: 'AAPL',
        from: DateTime.utc(2025, 6, 14),
        to: DateTime.utc(2025, 6, 15),
      );
      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });
  });
}
