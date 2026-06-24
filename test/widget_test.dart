import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffer/core/auth/pin_store.dart';
import 'package:coffer/core/crypto/password_kdf.dart';
import 'package:coffer/features/auth/presentation/auth_gate.dart';

PinStore _fastPinStore() => PinStore(
      storage: InMemoryPinKv(),
      kdf: PasswordKdf(memoryKib: 8, iterations: 1, hashLength: 16),
    );

void main() {
  testWidgets('AuthGate builds without crash when no PIN is set', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinStoreProvider.overrideWithValue(_fastPinStore()),
        ],
        child: const MaterialApp(
          home: AuthGate(child: Scaffold(body: Text('inside'))),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthGate), findsOneWidget);
  });
}
