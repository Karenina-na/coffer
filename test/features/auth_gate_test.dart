import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/core/auth/biometric_auth.dart';
import 'package:gwp/core/auth/pin_store.dart';
import 'package:gwp/core/crypto/password_kdf.dart';
import 'package:gwp/data/providers/account_providers.dart';
import 'package:gwp/features/auth/presentation/auth_gate.dart';
import 'package:gwp/features/settings/presentation/settings_page.dart';

/// 测试用的快速 KDF，避免 Argon2id 默认参数在测试 VM 里跑几秒。
PinStore _fastPinStore() => PinStore(
  storage: InMemoryPinKv(),
  kdf: PasswordKdf(memoryKib: 8, iterations: 1, hashLength: 16),
);

class _AlwaysSucceed implements BiometricAuth {
  @override
  Future<bool> canCheckBiometrics() async => true;
  @override
  Future<bool> authenticate({required String reason}) async => true;
}

class _AlwaysFail implements BiometricAuth {
  @override
  Future<bool> canCheckBiometrics() async => true;
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

Future<void> _pumpGate(
  WidgetTester tester, {
  required PinStore pin,
  required BiometricAuth biometric,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pinStoreProvider.overrideWithValue(pin),
        biometricAuthProvider.overrideWithValue(biometric),
      ],
      child: const MaterialApp(
        home: AuthGate(child: Scaffold(body: Text('inside'))),
      ),
    ),
  );
}

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).first);
    await tester.pump();
  }
}

/// 代替 pumpAndSettle：锁屏/setup 页面存在 CircularProgressIndicator 无限动画，
/// pumpAndSettle 会永远等下去。这里用 runAsync 让 Argon2id/真异步跑完，再 pump 几帧。
Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

GoRouter _buildSettingsLockRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/settings'),
              child: const Text('open-settings'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    ],
  );
}

Future<void> _pumpGateWithRouter(
  WidgetTester tester, {
  required PinStore pin,
  required BiometricAuth biometric,
}) async {
  late ProviderContainer container;
  final router = _buildSettingsLockRouter();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pinStoreProvider.overrideWithValue(pin),
        biometricAuthProvider.overrideWithValue(biometric),
        databaseSchemaVersionProvider.overrideWithValue(1),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                AuthGate(child: child ?? const SizedBox()),
          );
        },
      ),
    ),
  );
  await tester.pump();
  container.read(isUnlockedProvider.notifier).unlock();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('未设置 PIN → 进入创建 PIN 流程', (tester) async {
    final pin = _fastPinStore();
    await _pumpGate(tester, pin: pin, biometric: const AllowAllBiometric());
    await _flush(tester);

    expect(find.text('创建 6 位 PIN 码'), findsOneWidget);
    expect(find.text('inside'), findsNothing);
  });

  testWidgets('创建 PIN 完成后进入锁屏', (tester) async {
    final pin = _fastPinStore();
    await _pumpGate(tester, pin: pin, biometric: const AllowAllBiometric());
    await _flush(tester);

    await _tapDigits(tester, '123456');
    await _flush(tester);
    expect(find.text('再次输入以确认'), findsOneWidget);

    await _tapDigits(tester, '123456');
    await _flush(tester);
    expect(find.text('输入 PIN 码'), findsOneWidget);
  });

  testWidgets('已设置 PIN + 生物识别启用 → 自动放行', (tester) async {
    final pin = _fastPinStore();
    await pin.setPin('123456');
    await pin.setBiometricEnabled(true);

    await _pumpGate(tester, pin: pin, biometric: _AlwaysSucceed());
    await _flush(tester);

    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('生物识别失败后停留在锁屏，可用 PIN 解锁', (tester) async {
    final pin = _fastPinStore();
    await pin.setPin('123456');
    await pin.setBiometricEnabled(true);

    await _pumpGate(tester, pin: pin, biometric: _AlwaysFail());
    await _flush(tester);

    expect(find.text('输入 PIN 码'), findsOneWidget);
    expect(find.text('inside'), findsNothing);

    await _tapDigits(tester, '123456');
    await _flush(tester);
    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('确认 PIN 不一致 → 退回首步并显示错误，再次尝试可成功', (tester) async {
    final pin = _fastPinStore();
    await _pumpGate(tester, pin: pin, biometric: const AllowAllBiometric());
    await _flush(tester);

    // 第一次：输入 111111
    await _tapDigits(tester, '111111');
    await _flush(tester);
    expect(find.text('再次输入以确认'), findsOneWidget);

    // 确认输入 222222（不一致）
    await _tapDigits(tester, '222222');
    await _flush(tester);

    // 应退回首步并提示
    expect(find.text('两次输入不一致，请重新设置'), findsOneWidget);
    expect(find.text('创建 6 位 PIN 码'), findsOneWidget);

    // 再次尝试：一致
    await _tapDigits(tester, '333333');
    await _flush(tester);
    expect(find.text('再次输入以确认'), findsOneWidget);
    await _tapDigits(tester, '333333');
    await _flush(tester);
    expect(find.text('输入 PIN 码'), findsOneWidget);
  });

  testWidgets('端到端：设置 PIN 后，用同一 PIN 在锁屏解锁', (tester) async {
    final pin = _fastPinStore();
    await _pumpGate(tester, pin: pin, biometric: const AllowAllBiometric());
    await _flush(tester);

    await _tapDigits(tester, '246810');
    await _flush(tester);
    await _tapDigits(tester, '246810');
    await _flush(tester);

    expect(find.text('输入 PIN 码'), findsOneWidget);

    await _tapDigits(tester, '246810');
    await _flush(tester);

    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('设置页立即锁定后输入正确 PIN 可回到首页且不报错', (tester) async {
    final pin = _fastPinStore();
    await pin.setPin('123456');

    await _pumpGateWithRouter(
      tester,
      pin: pin,
      biometric: const AllowAllBiometric(),
    );

    expect(find.text('open-settings'), findsOneWidget);
    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('立即锁定'));
    await tester.pump();
    await tester.pump();
    expect(find.text('输入 PIN 码'), findsOneWidget);

    await _tapDigits(tester, '123456');
    await _flush(tester);
    await tester.pumpAndSettle();

    expect(find.text('open-settings'), findsOneWidget);
    expect(find.text('设置'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN 错误显示提示', (tester) async {
    final pin = _fastPinStore();
    await pin.setPin('123456');

    await _pumpGate(tester, pin: pin, biometric: const AllowAllBiometric());
    await _flush(tester);

    await _tapDigits(tester, '000000');
    await _flush(tester);

    expect(find.textContaining('PIN 不正确'), findsOneWidget);
    expect(find.text('inside'), findsNothing);
  });
}
