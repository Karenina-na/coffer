import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/core/result.dart';
import 'package:coffer/data/providers/fx/cached_fx_price_provider.dart';
import 'package:coffer/data/providers/fx/frankfurter_provider.dart';
import 'package:coffer/domain/repositories/exchange_rate_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeLocalPriceProvider implements PriceProvider {
  final Map<String, Decimal> rates = const {};

  @override
  getRate({required String baseCurrency, required String quoteCurrency}) async {
    if (baseCurrency == quoteCurrency) {
      return Ok(Decimal.one);
    }
    final rate =
        rates['${baseCurrency.toUpperCase()}/${quoteCurrency.toUpperCase()}'];
    if (rate == null) {
      return const Err(NotFoundError('local miss'));
    }
    return Ok(rate);
  }
}

void main() {
  test('本地 miss 后重复查询同币对只请求一次远端', () async {
    var remoteCalls = 0;
    final remote = FrankfurterProvider(
      client: MockClient((request) async {
        remoteCalls++;
        expect(request.url.queryParameters['base'], 'USD');
        expect(request.url.queryParameters['symbols'], 'CNY');
        return http.Response(
          '{"base":"USD","date":"2026-04-28","rates":{"CNY":7.23}}',
          200,
        );
      }),
    );
    final provider = CachedFxPriceProvider(
      local: _FakeLocalPriceProvider(),
      remote: remote,
    );

    final first = await provider.getRate(
      baseCurrency: 'USD',
      quoteCurrency: 'CNY',
    );
    final second = await provider.getRate(
      baseCurrency: 'USD',
      quoteCurrency: 'CNY',
    );

    expect(first.isOk, isTrue);
    expect(second.isOk, isTrue);
    expect(first.valueOrNull, Decimal.parse('7.23'));
    expect(second.valueOrNull, Decimal.parse('7.23'));
    expect(remoteCalls, 1);
  });

  test('远端已拉取的币对会复用反向缓存', () async {
    var remoteCalls = 0;
    final remote = FrankfurterProvider(
      client: MockClient((request) async {
        remoteCalls++;
        expect(request.url.queryParameters['base'], 'USD');
        expect(request.url.queryParameters['symbols'], 'CNY');
        return http.Response(
          '{"base":"USD","date":"2026-04-28","rates":{"CNY":7.2}}',
          200,
        );
      }),
    );
    final provider = CachedFxPriceProvider(
      local: _FakeLocalPriceProvider(),
      remote: remote,
    );

    final direct = await provider.getRate(
      baseCurrency: 'USD',
      quoteCurrency: 'CNY',
    );
    final inverse = await provider.getRate(
      baseCurrency: 'CNY',
      quoteCurrency: 'USD',
    );

    expect(direct.valueOrNull, Decimal.parse('7.2'));
    expect(inverse.valueOrNull, Decimal.parse('0.138888888888'));
    expect(remoteCalls, 1);
  });

  test('并发请求同一 pair 只触发一次远端调用（Bug 6：inflight 去重）', () async {
    var remoteCalls = 0;
    final remote = FrankfurterProvider(
      client: MockClient((request) async {
        remoteCalls++;
        // Simulate a small delay to allow second request to arrive
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          '{"base":"USD","date":"2026-04-28","rates":{"CNY":7.1}}',
          200,
        );
      }),
    );
    final provider = CachedFxPriceProvider(
      local: _FakeLocalPriceProvider(),
      remote: remote,
    );

    // Fire two concurrent requests for the same pair
    final results = await Future.wait([
      provider.getRate(baseCurrency: 'USD', quoteCurrency: 'CNY'),
      provider.getRate(baseCurrency: 'USD', quoteCurrency: 'CNY'),
    ]);

    expect(results[0].isOk, isTrue);
    expect(results[1].isOk, isTrue);
    expect(results[0].valueOrNull, Decimal.parse('7.1'));
    expect(results[1].valueOrNull, Decimal.parse('7.1'));
    // Only one remote call despite two concurrent requests
    expect(remoteCalls, 1);
  });
}
