import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/app/router.dart';
import 'package:gwp/core/ui/region_meta.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/card.dart';
import 'package:gwp/domain/entities/watched_pair.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/card/presentation/card_providers.dart';
import 'package:gwp/features/event/presentation/event_providers.dart';
import 'package:gwp/features/exchange_rate/presentation/exchange_rate_providers.dart';

Future<void> _settleNav(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = buildRouter(initialLocation: '/rates');
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        regionMetaIndexProvider.overrideWith(
          (ref) => Stream.value(<String, RegionMeta>{}),
        ),
        accountListProvider.overrideWith(
          (ref) => Stream.value(const <Account>[]),
        ),
        cardListProvider.overrideWith(
          (ref) => Stream.value(const <BankCard>[]),
        ),
        watchedPairListProvider.overrideWith(
          (ref) => Stream.value(const <WatchedPair>[]),
        ),
        unreadEventCountProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('rapid main-nav taps stay responsive', (tester) async {
    await _pumpShell(tester);
    await _settleNav(tester);

    expect(find.text('汇率'), findsWidgets);
    expect(find.text('还没有关注的币对'), findsOneWidget);

    final cardsTab = find.text('卡片').last;
    final ratesTab = find.text('汇率').last;

    await tester.tap(cardsTab);
    await tester.pump();
    await tester.tap(ratesTab);
    await tester.pump();
    await tester.tap(cardsTab);
    await _settleNav(tester);

    expect(find.text('卡片'), findsWidgets);
    expect(find.text('还没有卡片'), findsAtLeastNWidgets(1));

    await tester.tap(ratesTab);
    await _settleNav(tester);

    expect(find.text('还没有关注的币对'), findsOneWidget);
  });

  testWidgets('tapping selected tab is a stable no-op', (tester) async {
    await _pumpShell(tester);
    await _settleNav(tester);

    final ratesTab = find.text('汇率').last;

    await tester.tap(ratesTab);
    await tester.pump();
    await tester.tap(ratesTab);
    await _settleNav(tester);

    expect(find.text('还没有关注的币对'), findsOneWidget);
  });
}
