import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:coffer/data/providers/account_providers.dart';
import 'package:coffer/features/auth/presentation/auth_gate.dart';
import 'package:coffer/features/settings/presentation/settings_page.dart';

/// 仅暴露 /settings 与 /backup 两个节点，用于断言 context.push('/backup')。
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/backup',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('BACKUP_ROUTE'))),
      ),
    ],
  );
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  int schemaVersion = 42,
}) async {
  tester.view.physicalSize = const Size(1080, 6600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseSchemaVersionProvider.overrideWithValue(schemaVersion),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('渲染三大分区与来自 provider 的 schema 版本', (tester) async {
    await _pumpSettings(tester, schemaVersion: 99);

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('数据'), findsOneWidget);
    expect(find.text('安全'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('备份与恢复'), findsOneWidget);
    expect(find.text('导出加密备份文件，或从备份恢复全部数据'), findsOneWidget);
    expect(find.text('PIN 与指纹'), findsOneWidget);
    expect(find.text('立即锁定'), findsOneWidget);
    expect(find.text('v0.1.0 (1)'), findsOneWidget);
    expect(find.text('v99'), findsOneWidget);
  });

  testWidgets('点击"立即锁定" → isUnlockedProvider 置为 false', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseSchemaVersionProvider.overrideWithValue(1)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(routerConfig: _buildRouter());
          },
        ),
      ),
    );
    await tester.pump();

    // 先把状态置为已解锁
    container.read(isUnlockedProvider.notifier).unlock();
    expect(container.read(isUnlockedProvider), isTrue);

    await tester.tap(find.text('立即锁定'));
    await tester.pump();

    expect(container.read(isUnlockedProvider), isFalse);
  });

  testWidgets('点击"备份与恢复" → 通过 go_router 跳到 /backup', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('BACKUP_ROUTE'), findsNothing);

    await tester.tap(find.text('备份与恢复'));
    await tester.pumpAndSettle();

    expect(find.text('BACKUP_ROUTE'), findsOneWidget);
  });

  testWidgets('演示数据入口默认可见，且点击弹出确认对话框', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('注入演示数据'), findsOneWidget);

    await tester.tap(find.text('注入演示数据'));
    await tester.pumpAndSettle();

    expect(find.text('注入演示数据？'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '取消'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '注入'), findsOneWidget);
  });

  testWidgets('确认对话框点击"取消" → 关闭对话框且不触发 SnackBar', (tester) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('注入演示数据'));
    await tester.pumpAndSettle();
    expect(find.text('注入演示数据？'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.text('注入演示数据？'), findsNothing);
    expect(find.text('正在注入数据…'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('每个 section 的可点击条目都渲染 chevron 指示', (tester) async {
    await _pumpSettings(tester);

    // "备份与恢复" / "PIN 与指纹" / "立即锁定" / "转账协议" / "国家 / 地区" /
    // "货币" / "清除所有数据" / "注入演示数据" / "开源许可" 都带 onTap → 都有 chevron_right
    // "应用名称" / "应用版本" / "数据库 Schema" / "数据存储" 仅展示 trailing/subtitle → 无 chevron
    final chevrons = find.byIcon(Icons.chevron_right);
    expect(chevrons, findsNWidgets(9));
  });
}
