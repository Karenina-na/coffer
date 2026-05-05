import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// 生物识别认证的抽象；便于在测试与非 iOS/Android 平台下替换实现。
///
/// ## 速率限制
/// 这里**不再做应用层 backoff**，而是依赖平台：
/// - iOS：Touch/Face ID 连续失败 5 次自动触发系统锁定，要求输入设备密码
/// - Android：`BiometricPrompt` 连续失败达阈值触发系统级 `BiometricErrorLockout`
///
/// 本层若再叠一层自己计数，用户体验会变差（例如一次误划指纹即"触发"），而安全增益
/// 有限。失败时 UI 层会主动掉回 PIN 键盘，PIN 本身有 5 次 → 30s 的独立 backoff
/// （见 `pin_store.dart`）。
abstract interface class BiometricAuth {
  /// 设备是否具备生物识别能力（已录入）。
  Future<bool> canCheckBiometrics();

  /// 触发一次生物识别；成功返回 true。
  Future<bool> authenticate({required String reason});
}

class LocalAuthBiometric implements BiometricAuth {
  LocalAuthBiometric([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final can = await _auth.canCheckBiometrics;
      if (!can) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('biometric check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      // local_auth 的 PlatformException 携带语义不同的 code：
      //   'LockedOut'           — 连续失败触发临时锁定（几秒到几分钟）
      //   'PermanentlyLockedOut'— 永久锁定，需输入设备 PIN/密码解锁
      //   'NotAvailable'        — 硬件不可用（如指纹传感器被遮挡）
      //   'NotEnrolled'         — 未录入生物识别
      //   其余（含用户取消）    — 按取消处理
      // 记录日志使安全相关状态可追查；UI 层可通过 canCheckBiometrics() 重新判断状态。
      if (kDebugMode) debugPrint('biometric authenticate failed: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('biometric authenticate unexpected error: $e');
      return false;
    }
  }
}

/// 永远放行（用于非移动平台 / 测试环境）。
class AllowAllBiometric implements BiometricAuth {
  const AllowAllBiometric();

  @override
  Future<bool> canCheckBiometrics() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => true;
}
