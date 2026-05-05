/// E2E 2: 认证完整流
///
/// PIN 设置 → 正确验证 → 错误验证 → 限流 → 解除 → 更换 PIN → 旧 PIN 失效 → 清除 PIN
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/auth/pin_store.dart';
import 'package:gwp/core/crypto/password_kdf.dart';

void main() {
  late PinStore store;

  // Use fast KDF params for testing
  final fastKdf = PasswordKdf(memoryKib: 4096, iterations: 2, parallelism: 1);

  setUp(() {
    store = PinStore(
      storage: InMemoryPinKv(),
      kdf: fastKdf,
    );
  });

  test('PIN 设置 → 正确验证 → 成功', () async {
    expect(await store.hasPin(), isFalse);

    await store.setPin('123456');
    expect(await store.hasPin(), isTrue);

    final result = await store.verifyPin('123456');
    expect(result.ok, isTrue);
    expect(result.isLocked, isFalse);
  });

  test('错误 PIN 验证返回 false 并减少剩余次数', () async {
    await store.setPin('1234');

    final r = await store.verifyPin('9999');
    expect(r.ok, isFalse);
    expect(r.remainingAttempts, PinStore.maxFailBeforeLock - 1);
    expect(r.isLocked, isFalse);
  });

  test('连续 5 次失败触发限流', () async {
    await store.setPin('1234');

    PinVerifyResult? last;
    for (var i = 0; i < PinStore.maxFailBeforeLock; i++) {
      last = await store.verifyPin('0000');
    }

    // 第 5 次失败后应锁定
    expect(last!.ok, isFalse);
    expect(last.lockedUntilMs, greaterThan(0));

    // 锁定期内再次验证，正确 PIN 也被拒绝
    final lockedResult = await store.verifyPin('1234');
    expect(lockedResult.ok, isFalse);
    expect(lockedResult.isLocked, isTrue);
  });

  test('setPin 后清零失败计数', () async {
    await store.setPin('1234');

    // 制造 3 次失败
    for (var i = 0; i < 3; i++) {
      await store.verifyPin('0000');
    }

    // 重设 PIN 后失败计数应清零
    await store.setPin('5678');
    final r = await store.verifyPin('0000');
    expect(r.remainingAttempts, PinStore.maxFailBeforeLock - 1);
  });

  test('更换 PIN 后旧 PIN 失效', () async {
    await store.setPin('1111');
    final oldOk = await store.verifyPin('1111');
    expect(oldOk.ok, isTrue);

    await store.setPin('2222');

    // 旧 PIN 不再有效
    final oldFail = await store.verifyPin('1111');
    expect(oldFail.ok, isFalse);

    // 新 PIN 有效
    final newOk = await store.verifyPin('2222');
    expect(newOk.ok, isTrue);
  });

  test('clear 后 hasPin 为 false 且验证失败', () async {
    await store.setPin('4321');
    expect(await store.hasPin(), isTrue);

    await store.clear();
    expect(await store.hasPin(), isFalse);

    // 验证任意 PIN 都应失败
    final r = await store.verifyPin('4321');
    expect(r.ok, isFalse);
  });

  test('PIN 格式验证：过短抛出 ArgumentError', () async {
    expect(() => store.setPin('123'), throwsA(isA<ArgumentError>()));
  });

  test('PIN 格式验证：非数字抛出 ArgumentError', () async {
    expect(() => store.setPin('abcd'), throwsA(isA<ArgumentError>()));
  });
}
