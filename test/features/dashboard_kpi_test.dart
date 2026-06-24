import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/features/dashboard/presentation/dashboard_providers.dart';

Decimal d(String v) => Decimal.parse(v);

void main() {
  group('computeCreditUsedRatio', () {
    test('limit 为 0 返回 0', () {
      expect(computeCreditUsedRatio(Decimal.zero, Decimal.zero), 0.0);
      expect(computeCreditUsedRatio(Decimal.zero, d('100')), 0.0);
    });

    test('limit 为负数也按 0 处理（防御性）', () {
      expect(computeCreditUsedRatio(d('-1'), d('10')), 0.0);
    });

    test('一半可用 → 0.5', () {
      expect(computeCreditUsedRatio(d('1000'), d('500')), 0.5);
    });

    test('全额未用 → 0.0', () {
      expect(computeCreditUsedRatio(d('1000'), d('1000')), 0.0);
    });

    test('全部已用 → 1.0', () {
      expect(computeCreditUsedRatio(d('1000'), Decimal.zero), 1.0);
    });

    test('available > limit（异常数据）被钳制为 0.0（负使用率）', () {
      // 例如临时提额后额度调低，availSum 暂时超过 limitSum
      expect(computeCreditUsedRatio(d('1000'), d('1500')), 0.0);
    });

    test('available < 0（异常数据）被钳制为 1.0', () {
      expect(computeCreditUsedRatio(d('1000'), d('-100')), 1.0);
    });

    test('高精度 Decimal 分母仍能正确计算', () {
      final ratio = computeCreditUsedRatio(
        d('9999.99'),
        d('3333.33'),
      );
      // 1 - 3333.33/9999.99 ≈ 0.6666
      expect(ratio, closeTo(0.6666, 0.001));
    });
  });
}
