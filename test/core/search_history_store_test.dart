import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/repositories/search_history_protector.dart';

void main() {
  test(
    'SearchHistoryProtector encrypts payload without plain text leakage',
    () async {
      final protector = SearchHistoryProtector(
        masterKeyLoader: () async => SecretKey(List<int>.filled(32, 7)),
      );

      const query = '招商银行';
      final payload = {
        'queries': [query],
        'visits': [
          {
            'feature': 'accounts',
            'targetId': 'acc-1',
            'label': '招商银行',
            'visitedAt': DateTime.utc(2025, 1, 1).toIso8601String(),
          },
        ],
      };

      final encrypted = await protector.encode(payload);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(contains(query)));

      final decoded = await protector.decode(encrypted!);
      expect(decoded, isNotNull);
      expect(decoded!['queries'], [query]);
    },
  );
}
