import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/providers/asset/yahoo_finance_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _chartJson({
  Object? currency = 'USD',
  List<int>? timestamps,
  List<Object?>? closes,
}) {
  final meta = <String, Object?>{
    'symbol': 'AAPL',
    'regularMarketPrice': 150.25,
    'regularMarketTime': 1749988800,
  };
  if (currency != null) meta['currency'] = currency;
  return jsonEncode({
    'chart': {
      'result': [
        {
          'meta': meta,
          'timestamp': timestamps ?? [1749902400, 1749988800],
          'indicators': {
            'quote': [
              {
                'close': closes ?? [149.5, 150.25],
              },
            ],
          },
        },
      ],
    },
  });
}

void main() {
  group('YahooFinanceProvider', () {
    test('最新价缺少币种时返回 malformedResponse', () async {
      final provider = YahooFinanceProvider(
        client: MockClient(
          (_) async => http.Response(_chartJson(currency: null), 200),
        ),
      );

      final r = await provider.fetchLatest('AAPL');

      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });

    test('最新价币种为空字符串时返回 malformedResponse', () async {
      final provider = YahooFinanceProvider(
        client: MockClient(
          (_) async => http.Response(_chartJson(currency: '  '), 200),
        ),
      );

      final r = await provider.fetchLatest('AAPL');

      expect(r.isErr, isTrue);
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });

    test('历史价缺少币种时返回 malformedResponse', () async {
      final provider = YahooFinanceProvider(
        client: MockClient(
          (_) async => http.Response(_chartJson(currency: null), 200),
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

    test('历史价拒绝 0 或负数 close', () async {
      final provider = YahooFinanceProvider(
        client: MockClient(
          (_) async => http.Response(_chartJson(closes: [149.5, 0]), 200),
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

    test('有效币种会被标准化为大写', () async {
      final provider = YahooFinanceProvider(
        client: MockClient(
          (_) async => http.Response(_chartJson(currency: 'usd'), 200),
        ),
      );

      final r = await provider.fetchLatest('AAPL');

      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.currency, 'USD');
    });
  });
}
