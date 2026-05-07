import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/card/presentation/card_create_page.dart';

void main() {
  testWidgets('卡片创建页其他支持币种来自字典而非手动输入', (tester) async {
    final now = DateTime.utc(2026, 1, 1);
    final account = Account(
      id: 'acc-1',
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'ICBC',
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    final currencies = [
      DictEntry(
        id: 1,
        type: DictType.currency,
        code: 'CNY',
        name: '人民币',
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 2,
        type: DictType.currency,
        code: 'USD',
        name: '美元',
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 3,
        type: DictType.currency,
        code: 'EUR',
        name: '欧元',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountListProvider.overrideWith((ref) => Stream.value([account])),
          dictEntriesProvider(DictType.currency).overrideWith(
            (ref) => Stream.value(currencies),
          ),
        ],
        child: const MaterialApp(home: CardCreatePage()),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('支持币种'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('自定义 ISO 代码'), findsNothing);
    expect(find.byKey(const Key('card-supported-currency-USD')), findsOneWidget);
    expect(find.byKey(const Key('card-supported-currency-EUR')), findsOneWidget);
    expect(find.byKey(const Key('card-supported-currency-CNY')), findsNothing);

    await tester.tap(find.byKey(const Key('card-supported-currency-USD')));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('card-supported-currency-USD')),
    );
    expect(chip.selected, isTrue);
  });
}
