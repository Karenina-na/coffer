import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:coffer/data/providers/dict_providers.dart';
import 'package:coffer/domain/entities/account.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/dict_entry.dart';
import 'package:coffer/domain/entities/dict_type.dart';
import 'package:coffer/features/account/presentation/account_providers.dart';
import 'package:coffer/features/asset/presentation/asset_create_page.dart';

void main() {
  testWidgets('资产创建页可预选并锁定归属账户', (tester) async {
    final now = DateTime.utc(2026, 1, 1);
    final account = Account(
      id: 'acc-1',
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'ICBC',
      status: AccountStatus.active,
      fxSpreadPercent: Decimal.zero,
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
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountListProvider.overrideWith((ref) => Stream.value([account])),
          dictEntriesProvider(
            DictType.currency,
          ).overrideWith((ref) => Stream.value(currencies)),
        ],
        child: const MaterialApp(
          home: AssetCreatePage(
            initialAccountId: 'acc-1',
            lockAccountSelection: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('当前入口已锁定归属账户'), findsOneWidget);
    final accountField = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(accountField.initialValue, 'acc-1');
    expect(accountField.onChanged, isNull);
  });
}
