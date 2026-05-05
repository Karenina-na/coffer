import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/providers/network_error.dart';

void main() {
  group('classifyHttpStatus', () {
    test('错误消息只保留单行摘要', () {
      final error = classifyHttpStatus(
        'demo',
        500,
        'line 1\nline 2 with token=secret\nline 3',
      );

      expect(
        error.message,
        contains('demo http 500: line 1 line 2 with token=secret line 3'),
      );
      expect(error.message, isNot(contains('\n')));
    });

    test('长响应体会被截断后再返回给 UI', () {
      final longBody = 'x' * 200;
      final error = classifyHttpStatus('demo', 400, longBody);

      expect(error.message, startsWith('demo http 400: '));
      expect(error.message, contains('…'));
      expect(error.message.length, lessThan(longBody.length));
    });
  });
}
