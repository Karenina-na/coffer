import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误捕获：避免未处理异常直接把应用打挂。
  // 本地优先应用没有远端上报通道，此处仅做结构化日志，供开发期排查。
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  // 通知服务需在 runApp 前完成 channel 初始化；失败不阻塞应用启动。
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: CofferApp()));
}

class CofferApp extends StatefulWidget {
  const CofferApp({super.key});

  @override
  State<CofferApp> createState() => _CofferAppState();
}

class _CofferAppState extends State<CofferApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = buildDarkTheme();
    return MaterialApp.router(
      title: 'Coffer',
      themeMode: ThemeMode.dark,
      theme: dark,
      darkTheme: dark,
      routerConfig: _router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: MediaQuery.textScalerOf(context)),
          child: AuthGate(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
