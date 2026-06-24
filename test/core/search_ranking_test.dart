import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/search/search_ranking.dart';

void main() {
  group('scoreText', () {
    test('完全相等返回 100', () {
      expect(scoreText('Hello', 'hello'), 100);
      expect(scoreText('abc', 'abc'), 100);
    });

    test('前缀匹配返回 80', () {
      expect(scoreText('Hello World', 'hello'), 80);
      expect(scoreText('账户余额', '账户'), 80);
    });

    test('词首匹配返回 60（分隔符后）', () {
      expect(scoreText('招商-储蓄', '储蓄'), 60);
      expect(scoreText('my_card_visa', 'visa'), 60);
      expect(scoreText('asset/stock', 'stock'), 60);
      expect(scoreText('foo bar', 'bar'), 60);
      expect(scoreText('a·b', 'b'), 60);
    });

    test('普通子串匹配返回 40', () {
      expect(scoreText('招商储蓄', '储蓄'), 40);
      expect(scoreText('abcdefg', 'cde'), 40);
    });

    test('不匹配返回 0', () {
      expect(scoreText('hello', 'xyz'), 0);
      expect(scoreText('中文', 'en'), 0);
    });

    test('空输入返回 0', () {
      expect(scoreText('', 'abc'), 0);
      expect(scoreText('abc', ''), 0);
      expect(scoreText('', ''), 0);
    });

    test('大小写不敏感', () {
      expect(scoreText('HELLO', 'hello'), 100);
      expect(scoreText('FooBar', 'foobar'), 100);
      expect(scoreText('BankOfAmerica', 'bank'), 80);
    });

    test('query 必须是小写（约定）— 大写 query 不会匹配', () {
      // 约定调用方必须先 lowercaseQuery；若传大写则 haystack.toLowerCase()
      // 不会匹配到。
      expect(scoreText('hello', 'HELLO'), 0);
    });
  });

  group('scoreMax', () {
    test('返回多字段中的最高分', () {
      expect(scoreMax(['储蓄卡', '招商银行'], '储蓄'), 80);
      expect(scoreMax(['招商银行', '储蓄卡'], '储蓄'), 80);
    });

    test('命中 100 时短路', () {
      expect(scoreMax(['exact', 'other', 'more'], 'exact'), 100);
    });

    test('全部不命中返回 0', () {
      expect(scoreMax(['a', 'b', 'c'], 'xyz'), 0);
    });

    test('空字段与 null 被跳过', () {
      expect(scoreMax([null, '', 'foo'], 'foo'), 100);
      expect(scoreMax([null, null], 'x'), 0);
      expect(scoreMax([], 'x'), 0);
    });

    test('从子串升级到前缀', () {
      // 'abc' 在 "xabc" 是子串(40)，在 "abcx" 是前缀(80)
      expect(scoreMax(['xabc', 'abcx'], 'abc'), 80);
    });

    test('排序等价性：更高分的字段被选中', () {
      final r1 = scoreMax(['商店-储蓄卡', '其它'], '储蓄'); // 词首 60
      final r2 = scoreMax(['储蓄商店', '其它'], '储蓄'); // 前缀 80
      expect(r2, greaterThan(r1));
    });
  });
}
