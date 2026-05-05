import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/providers/fx/frankfurter_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FrankfurterProvider', () {
    test('最新汇率拒绝目标币种的零值', () async {
      final provider = FrankfurterProvider(
        client: MockClient((_) async {
          return http.Response(
            '{"base":"USD","date":"2026-04-28","rates":{"CNY":0}}',
            200,
          );
        }),
      );

      final r = await provider.fetchLatest(base: 'USD', symbols: ['CNY']);

      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });

    test('最新汇率拒绝目标币种的负值', () async {
      final provider = FrankfurterProvider(
        client: MockClient((_) async {
          return http.Response(
            '{"base":"USD","date":"2026-04-28","rates":{"CNY":-7.2}}',
            200,
          );
        }),
      );

      final r = await provider.fetchLatest(base: 'USD', symbols: ['CNY']);

      expect(r.isErr, isTrue);
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });

    test('历史汇率拒绝目标币种的非正值', () async {
      final provider = FrankfurterProvider(
        client: MockClient((_) async {
          return http.Response(
            '{"base":"USD","rates":{"2026-04-28":{"CNY":0}}}',
            200,
          );
        }),
      );

      final r = await provider.fetchTimeSeries(
        base: 'USD',
        symbols: ['CNY'],
        from: DateTime.utc(2026, 4, 28),
        to: DateTime.utc(2026, 4, 28),
      );

      expect(r.isErr, isTrue);
      expect(r.errorOrNull, isA<NetworkError>());
      expect(
        (r.errorOrNull as NetworkError).kind,
        NetworkErrorKind.malformedResponse,
      );
    });

    test('有效正汇率正常返回', () async {
      final provider = FrankfurterProvider(
        client: MockClient((_) async {
          return http.Response(
            '{"base":"USD","date":"2026-04-28","rates":{"CNY":7.23}}',
            200,
          );
        }),
      );

      final r = await provider.fetchLatest(base: 'USD', symbols: ['CNY']);

      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.rates['CNY'], Decimal.parse('7.23'));
    });
  });
}
