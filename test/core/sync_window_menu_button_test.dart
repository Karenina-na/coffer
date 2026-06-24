import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffer/core/ui/sync_window_menu_button.dart';

void main() {
  testWidgets('sync window menu button shows unified windows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SyncWindowMenuButton(
              tooltip: '同步当前资产',
              onSelected: (_) {},
              child: const Icon(Icons.sync),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.sync));
    await tester.pumpAndSettle();

    expect(find.text('8日'), findsOneWidget);
    expect(find.text('1个月'), findsOneWidget);
    expect(find.text('1年'), findsOneWidget);
    expect(find.text('5年'), findsOneWidget);
  });
}
