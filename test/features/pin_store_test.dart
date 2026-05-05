import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/core/auth/pin_store.dart';
import 'package:gwp/core/crypto/password_kdf.dart';

void main() {
  // 测试里用更快参数，避免单测变慢
  PinStore makeStore() => PinStore(
        storage: InMemoryPinKv(),
        kdf: PasswordKdf(memoryKib: 1024, iterations: 1, hashLength: 32),
      );

  test('初始未设置 PIN', () async {
    final s = makeStore();
    expect(await s.hasPin(), isFalse);
    final r = await s.verifyPin('123456');
    expect(r.ok, isFalse);
  });

  test('setPin + verify 正确/错误', () async {
    final s = makeStore();
    await s.setPin('123456');
    expect(await s.hasPin(), isTrue);

    final ok = await s.verifyPin('123456');
    expect(ok.ok, isTrue);

    final bad = await s.verifyPin('000000');
    expect(bad.ok, isFalse);
    expect(bad.remainingAttempts, PinStore.maxFailBeforeLock - 1);
  });

  test('连续失败触发冷却', () async {
    final s = makeStore();
    await s.setPin('654321');
    PinVerifyResult last = const PinVerifyResult(
      ok: false,
      lockedUntilMs: 0,
      remainingAttempts: 0,
    );
    for (var i = 0; i < PinStore.maxFailBeforeLock; i++) {
      last = await s.verifyPin('111111');
    }
    expect(last.ok, isFalse);
    expect(last.lockedUntilMs, greaterThan(DateTime.now().millisecondsSinceEpoch));

    // 处于冷却期：再试一次不消耗计数，返回 locked
    final locked = await s.verifyPin('654321');
    expect(locked.ok, isFalse);
    expect(locked.lockedUntilMs, greaterThan(DateTime.now().millisecondsSinceEpoch));
  });

  test('成功校验清零失败计数', () async {
    final s = makeStore();
    await s.setPin('222222');
    await s.verifyPin('000000'); // 1 次失败
    await s.verifyPin('111111'); // 2 次失败
    final ok = await s.verifyPin('222222');
    expect(ok.ok, isTrue);
    // 成功后失败计数归零：接下来一次失败还剩 maxFailBeforeLock - 1
    final after = await s.verifyPin('000000');
    expect(after.remainingAttempts, PinStore.maxFailBeforeLock - 1);
  });

  test('setPin 格式校验', () async {
    final s = makeStore();
    expect(() => s.setPin('abc'), throwsArgumentError); // 非数字
    expect(() => s.setPin('12'), throwsArgumentError); // 太短
    expect(() => s.setPin('123456789'), throwsArgumentError); // 太长
  });

  test('生物识别开关持久化', () async {
    final s = makeStore();
    expect(await s.isBiometricEnabled(), isFalse);
    await s.setBiometricEnabled(true);
    expect(await s.isBiometricEnabled(), isTrue);
    await s.setBiometricEnabled(false);
    expect(await s.isBiometricEnabled(), isFalse);
  });

  test('clear 重置所有状态', () async {
    final s = makeStore();
    await s.setPin('333333');
    await s.setBiometricEnabled(true);
    await s.clear();
    expect(await s.hasPin(), isFalse);
    expect(await s.isBiometricEnabled(), isFalse);
  });
}
