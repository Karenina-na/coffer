import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/core/ui/app_top_bar.dart';
import 'package:gwp/core/ui/top_search_action.dart';

Widget _buildHarness({required double width}) {
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: const MaterialApp(
        home: _TopBarTestScaffold(title: '很长很长很长很长的页面标题'),
      ),
    ),
  );
}

class _TopBarTestScaffold extends ConsumerStatefulWidget {
  const _TopBarTestScaffold({required this.title});

  final String title;

  @override
  ConsumerState<_TopBarTestScaffold> createState() => _TopBarTestScaffoldState();
}

class _TopBarTestScaffoldState extends ConsumerState<_TopBarTestScaffold> {
  late final TopSearchOpener _topSearchOpener;

  @override
  void initState() {
    super.initState();
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _topSearchOpener.set(this, () {});
    });
  }

  @override
  void dispose() {
    _topSearchOpener.clearLater(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: Text(widget.title),
        showFixedActions: true,
        showAppIcon: false,
      ),
      body: const SizedBox.shrink(),
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/a',
    routes: [
      GoRoute(
        path: '/a',
        builder: (context, state) => const _TopBarTestScaffold(title: '第一页'),
      ),
      GoRoute(
        path: '/b',
        builder: (context, state) => const _TopBarTestScaffold(title: '第二页'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(body: Text('设置页')),
      ),
    ],
  );
}

void main() {
  testWidgets('compact top bar keeps search settings and overflow inline', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(width: 320));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('搜索'), findsOneWidget);
    expect(find.byTooltip('设置'), findsOneWidget);
    expect(find.byTooltip('更多'), findsOneWidget);
    expect(find.byType(TopSearchAction), findsOneWidget);
    expect(find.text('数据同步'), findsNothing);
    expect(find.text('本位币'), findsNothing);

    await tester.tap(find.byTooltip('更多'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('更多操作'), findsOneWidget);
    expect(find.byTooltip('关闭'), findsOneWidget);
    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('本位币'), findsOneWidget);
    expect(find.text('刷新全部'), findsNothing);
    expect(find.text('当前本位币'), findsNothing);
    expect(find.text('设置'), findsNothing);

    await tester.tap(find.text('数据同步'));
    await tester.pumpAndSettle();

    expect(find.text('刷新全部'), findsOneWidget);
    expect(find.text('仅汇率'), findsOneWidget);
    expect(find.text('仅资产'), findsOneWidget);

    await tester.tap(find.text('刷新全部'));
    await tester.pumpAndSettle();

    expect(find.text('8日'), findsOneWidget);
    expect(find.text('1个月'), findsOneWidget);
    expect(find.text('1年'), findsOneWidget);
    expect(find.text('5年'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('本位币'));
    await tester.pumpAndSettle();

    expect(find.text('当前本位币'), findsOneWidget);
  });

  testWidgets('wide top bar also keeps sync and currency in overflow only', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(width: 430));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('搜索'), findsOneWidget);
    expect(find.byTooltip('设置'), findsOneWidget);
    expect(find.byTooltip('更多'), findsOneWidget);
    expect(find.text('数据同步'), findsNothing);
    expect(find.text('本位币'), findsNothing);

    await tester.tap(find.byTooltip('更多'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('本位币'), findsOneWidget);
    expect(find.text('刷新全部'), findsNothing);
    expect(find.text('当前本位币'), findsNothing);
  });

  testWidgets('switching pages does not drop the search action', (tester) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(size: Size(320, 800)),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('搜索'), findsOneWidget);

    router.go('/b');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('第二页'), findsOneWidget);
    expect(find.byTooltip('搜索'), findsOneWidget);
    expect(find.byTooltip('设置'), findsOneWidget);
    expect(find.byTooltip('更多'), findsOneWidget);
  });
}
