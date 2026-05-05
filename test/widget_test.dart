import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/main.dart';

void main() {
  testWidgets('Coffer app boots', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(MaterialApp), findsOneWidget);
    // Sanity check that main library symbol is referenced.
    expect(CofferApp, isNotNull);
  });
}
