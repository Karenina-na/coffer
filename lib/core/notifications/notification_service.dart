import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务：汇率预警/同步过期等 MEDIUM 优先事件，可选项走系统通知栏。
///
/// 设计要点：
/// - 仅 Android 生效（POST_NOTIFICATIONS 权限），iOS 调用会静默成功（init 失败不抛）。
/// - 通知不承载敏感数据，只显示 "USD/CNY 触及上沿 7.30" 这类概述。
/// - 幂等键沿用 RATE_ALERT 的 sourceKey 哈希，避免同一条事件多次推送。
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;
  bool _enabled = true; // 运行时可由设置页切换
  final Set<int> _sentIds = <int>{};

  bool get enabled => _enabled;
  void setEnabled(bool v) => _enabled = v;

  /// `main()` 启动期调用；失败不抛异常（通知是辅助功能，失败不应阻塞登录）。
  Future<void> init() async {
    if (_inited) return;
    _inited = true; // Set before await to prevent race
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);
      if (!kIsWeb && Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      }
    } catch (e) {
      _inited = false;
      if (kDebugMode) {
        debugPrint('NotificationService.init skipped: $e');
      }
    }
  }

  /// 展示一条汇率预警通知。`sourceKey` 用于生成稳定 ID，保证同一事件不重推。
  Future<void> showRateAlert({
    required String sourceKey,
    required String pairKey,
    required String summary,
  }) async {
    if (!_enabled || !_inited) return;
    final id = sourceKey.hashCode & 0x7fffffff;
    if (_sentIds.contains(id)) return;
    _sentIds.add(id);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rate_alert',
        '汇率预警',
        channelDescription: '关注币对触及阈值/波动时的本地通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        category: AndroidNotificationCategory.reminder,
      ),
    );
    try {
      await _plugin.show(id, '汇率预警 · $pairKey', summary, details);
    } catch (e) {
      if (kDebugMode) debugPrint('showRateAlert failed: $e');
    }
  }
}
