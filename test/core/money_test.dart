import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/money/money.dart';

void main() {
  group('Money', () {
    test('parseOrNull handles null/empty', () {
      expect(Money.parseOrNull(null), isNull);
      expect(Money.parseOrNull(''), isNull);
      expect(Money.parseOrNull('123.4500000000'), Decimal.parse('123.45'));
    });

    test('stringifyOrNull round-trips with parseOrNull', () {
      final d = Decimal.parse('12345.67890000');
      final s = Money.stringifyOrNull(d);
      expect(Money.parseOrNull(s), d);
    });

    test('format uses unified 4dp display precision by default', () {
      final cny =
          Money.format(Decimal.parse('1234.5'), currency: 'CNY', locale: 'en');
      expect(cny, contains('1,234.5000'));

      final btc =
          Money.format(Decimal.parse('0.12345678'), currency: 'BTC', locale: 'en');
      expect(btc, contains('0.1235'));
    });

    test('format keeps full precision for very large amounts (no double)', () {
      // 17 位整数 + 2 位小数，超出 double 53-bit 精度范围；
      // 若实现仍经过 double，尾部会被 0 抹掉。
      final huge = Money.format(
        Decimal.parse('99999999999999999.99'),
        currency: 'USD',
        locale: 'en',
      );
      expect(huge, contains('99,999,999,999,999,999.99'));
    });

    test('format handles negative values', () {
      final v =
          Money.format(Decimal.parse('-1234.5'), currency: 'USD', locale: 'en');
      expect(v.startsWith('-'), isTrue);
      expect(v, contains('1,234.5000'));
    });

    test('formatDecimal rounds half-up to 4dp for display', () {
      expect(Money.formatDecimal(Decimal.parse('1.23454')), '1.2345');
      expect(Money.formatDecimal(Decimal.parse('1.23455')), '1.2346');
    });

    test('formatPercent helpers keep 4dp and optional sign', () {
      expect(Money.formatPercent(Decimal.parse('12.3')), '12.3000%');
      expect(
        Money.formatPercent(Decimal.parse('12.3'), alwaysShowSign: true),
        '+12.3000%',
      );
      expect(
        Money.formatPercentFromDouble(-0.1256, alwaysShowSign: true),
        '-0.1256%',
      );
    });

    test('ratio handles infinite precision rationals', () {
      expect(
        Money.ratio(Decimal.one, Decimal.fromInt(3)).toString(),
        '0.3333333333',
      );
    });

    test('percent handles infinite precision rationals', () {
      expect(
        Money.percent(Decimal.one, Decimal.fromInt(3)).toString(),
        '33.3333333333',
      );
    });

    test('ratio and percent return zero for zero denominator', () {
      expect(Money.ratio(Decimal.one, Decimal.zero), Decimal.zero);
      expect(Money.percent(Decimal.one, Decimal.zero), Decimal.zero);
    });
  });
}
