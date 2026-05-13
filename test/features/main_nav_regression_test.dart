import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/app/router.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/core/ui/gwp_bar_rank.dart';
import 'package:gwp/core/ui/gwp_node_map.dart';
import 'package:gwp/core/ui/gwp_radar_chart.dart';
import 'package:gwp/core/ui/horizontal_gesture_guard.dart';
import 'package:gwp/core/ui/region_meta.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/card.dart';
import 'package:gwp/domain/entities/card_enums.dart';
import 'package:gwp/domain/entities/domain_event.dart';
import 'package:gwp/domain/entities/event_enums.dart';
import 'package:gwp/domain/entities/exchange_rate.dart';
import 'package:gwp/domain/entities/exchange_rate_enums.dart';
import 'package:gwp/domain/entities/watched_pair.dart';
import 'package:gwp/domain/events/event_bus.dart';
import 'package:gwp/domain/repositories/asset_repository.dart';
import 'package:gwp/domain/repositories/event_repository.dart';
import 'package:gwp/domain/repositories/exchange_rate_repository.dart';
import 'package:gwp/domain/usecases/check_asset_sync_outdated.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/asset/presentation/asset_providers.dart';
import 'package:gwp/features/card/presentation/card_providers.dart';
import 'package:gwp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:gwp/features/event/presentation/event_providers.dart';
import 'package:gwp/features/exchange_rate/presentation/exchange_rate_providers.dart';
import 'package:gwp/features/holdings/presentation/portfolio_providers.dart' as holdings;

Future<void> _settleNav(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _swipeLeft(WidgetTester tester, Offset start) async {
  await tester.flingFrom(start, const Offset(-220, 0), 1200);
  await _settleNav(tester);
}

Future<void> _swipeRight(WidgetTester tester, Offset start) async {
  await tester.flingFrom(start, const Offset(220, 0), 1200);
  await _settleNav(tester);
}

final _ratesTestPair = WatchedPair(
  pairKey: 'USD/CNY',
  baseCurrency: 'USD',
  quoteCurrency: 'CNY',
  createdAt: DateTime(2026, 1, 1),
);

final _ratesTestSeries = <ExchangeRate>[
  ExchangeRate(
    id: 'rate-1',
    pairKey: 'USD/CNY',
    baseCurrency: 'USD',
    quoteCurrency: 'CNY',
    rate: Decimal.parse('7.1000'),
    asOfTime: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
    source: 'test',
    snapshotType: SnapshotType.daily,
  ),
  ExchangeRate(
    id: 'rate-2',
    pairKey: 'USD/CNY',
    baseCurrency: 'USD',
    quoteCurrency: 'CNY',
    rate: Decimal.parse('7.2000'),
    asOfTime: DateTime(2026, 1, 2, 9),
    updatedAt: DateTime(2026, 1, 2, 9),
    source: 'test',
    snapshotType: SnapshotType.daily,
  ),
];

final _dashboardTestCard = BankCard(
  id: 'card-1',
  accountId: 'account-1',
  cardOrganization: 'VISA',
  cardNoMasked: '**** 1234',
  cardType: CardType.credit,
  expireMonth: 12,
  expireYear: 2030,
  issuerName: 'Test Bank',
  billingCycleDay: 15,
  paymentDueDay: 20,
  status: CardStatus.active,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _eventCalendarSeed = DomainEvent(
  id: 'event-1',
  eventType: '账单提醒',
  relatedModel: RelatedModel.card,
  relatedId: 'card-1',
  triggerTime: DateTime(2026, 1, 15, 9),
  status: EventStatus.pending,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  String initialLocation = '/rates',
  bool seedRatesList = false,
  bool seedDashboardBills = false,
  bool seedEventCalendar = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = buildRouter(initialLocation: initialLocation);
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
          (ref) => Stream.value(
            seedDashboardBills ? <BankCard>[_dashboardTestCard] : const <BankCard>[],
          ),
        ),
        watchedPairListProvider.overrideWith(
          (ref) => Stream.value(
            seedRatesList ? <WatchedPair>[_ratesTestPair] : const <WatchedPair>[],
          ),
        ),
        exchangeRateRepositoryProvider.overrideWith(
          (ref) => _FakeExchangeRateRepository(
            pairSeries: seedRatesList
                ? <String, List<ExchangeRate>>{'USD/CNY': _ratesTestSeries}
                : const <String, List<ExchangeRate>>{},
          ),
        ),
        unreadEventCountProvider.overrideWith((ref) => 0),
        pendingAckEventsProvider.overrideWith(
          (ref) => Stream.value(const <DomainEvent>[]),
        ),
        recentEventsProvider.overrideWith(
          (ref) => Stream.value(
            seedEventCalendar ? <DomainEvent>[_eventCalendarSeed] : const <DomainEvent>[],
          ),
        ),
        checkAssetSyncOutdatedUseCaseProvider.overrideWith(
          (ref) => CheckAssetSyncOutdatedUseCase(
            assets: _FakeAssetRepository(),
            events: _FakeEventRepository(),
            bus: DomainEventBus(),
            idGenerator: () => 'test-id',
            now: DateTime.now,
          ),
        ),
        dashboardSummaryProvider.overrideWith(
          (ref) async => DashboardSummary(
            baseCurrency: 'CNY',
            total: Decimal.zero,
            accountCount: 0,
            assetCount: 0,
            missingAssetIds: const <String>[],
          ),
        ),
        holdings.portfolioSnapshotProvider.overrideWith(
          (ref) async => holdings.PortfolioSnapshot(
            netWorth: Decimal.zero,
            baseCurrency: 'CNY',
            accountCount: 0,
            assetCount: 0,
            currencyCount: 0,
            regionCount: 0,
            institutionCount: 0,
            missingRateCount: 0,
          ),
        ),
        dashboardKpiProvider.overrideWith(
          (ref) async => DashboardKpi(
            assetCount: 0,
            accountCount: 0,
            cardCount: seedDashboardBills ? 1 : 0,
            creditCardCount: seedDashboardBills ? 1 : 0,
            creditUsedRatio: 0,
            pendingEventCount: 0,
            criticalEventCount: 0,
            regionSet: <String>{},
          ),
        ),
        allocationByCurrencyProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        allocationByTypeProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        allocationByRegionProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        nodeMapDataProvider.overrideWith(
          (ref) async => const NodeMapData(nodes: <MapNode>[], edges: <MapEdge>[]),
        ),
        nodeMapAggregateDataProvider.overrideWith(
          (ref) async => const NodeMapData(nodes: <MapNode>[], edges: <MapEdge>[]),
        ),
        netWorthTrendProvider.overrideWith(
          (ref) async => const <TrendPoint>[],
        ),
        trendDeltaProvider.overrideWith(
          (ref) async => const TrendDelta(
            points: <TrendPoint>[],
            startValue: 0,
            endValue: 0,
            minValue: 0,
            maxValue: 0,
          ),
        ),
        recentActivitiesProvider.overrideWith(
          (ref) async => const <DomainEvent>[],
        ),
        todaysRateAlertsProvider.overrideWith(
          (ref) async => const <DomainEvent>[],
        ),
        holdings.portfolioByTypeProvider.overrideWith(
          (ref) async => const <holdings.AllocationSlice>[],
        ),
        holdings.portfolioByCurrencyProvider.overrideWith(
          (ref) async => const <holdings.AllocationSlice>[],
        ),
        holdings.portfolioByRegionProvider.overrideWith(
          (ref) async => const <holdings.AllocationSlice>[],
        ),
        holdings.portfolioByInstitutionProvider.overrideWith(
          (ref) async => const <holdings.AllocationSlice>[],
        ),
        holdings.assetTop10Provider.overrideWith(
          (ref) async => const <RankItem>[],
        ),
        holdings.currencyExposureProvider.overrideWith(
          (ref) async => const holdings.HeatMatrixData(
            accounts: <String>[],
            currencies: <String>[],
            cells: <(String, String), double>{},
            maxValue: 0,
          ),
        ),
        holdings.concentrationProvider.overrideWith(
          (ref) async => const holdings.ConcentrationMetrics(
            assetHhi: 0,
            currencyHhi: 0,
            regionHhi: 0,
            top3Share: 0,
            top3Labels: <String>[],
            largestLabel: '-',
            largestShare: 0,
          ),
        ),
        holdings.liquidityProvider.overrideWith(
          (ref) async => const holdings.LiquidityProfile(
            highValue: 0,
            medValue: 0,
            lowValue: 0,
            total: 0,
          ),
        ),
        holdings.healthScoreProvider.overrideWith(
          (ref) async => const <RadarDimension>[],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}

class _FakeAssetRepository implements AssetRepository {
  @override
  Stream<List<Asset>> watchAll() => Stream.value(const <Asset>[]);

  @override
  Stream<List<Asset>> watchByAccount(String accountId) =>
      Stream.value(const <Asset>[]);

  @override
  Stream<Asset?> watchById(String id) => Stream.value(null);

  @override
  Future<Result<Asset, AppError>> findById(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Result<Asset, AppError>>> findByIds(List<String> ids) =>
      Future.error(UnimplementedError());

  @override
  Future<Result<Asset, AppError>> create(Asset asset) =>
      Future.error(UnimplementedError());

  @override
  Future<Result<Asset, AppError>> update(Asset asset) =>
      Future.error(UnimplementedError());

  @override
  Future<Result<void, AppError>> updateStatus(String id, status) =>
      Future.error(UnimplementedError());

  @override
  Future<Result<void, AppError>> softDelete(String id) =>
      Future.error(UnimplementedError());
}

class _FakeExchangeRateRepository implements ExchangeRateRepository {
  _FakeExchangeRateRepository({required this.pairSeries});

  final Map<String, List<ExchangeRate>> pairSeries;

  @override
  Future<Result<ExchangeRate, AppError>> latestFor({
    required String baseCurrency,
    required String quoteCurrency,
  }) => Future.error(UnimplementedError());

  @override
  Stream<List<ExchangeRate>> watchAll({int limit = 200}) =>
      Stream.value(const <ExchangeRate>[]);

  @override
  Stream<List<ExchangeRate>> watchSeriesForPair({
    required String pairKey,
    required DateTime since,
  }) {
    final series = pairSeries[pairKey] ?? const <ExchangeRate>[];
    return Stream.value(
      series.where((rate) => !rate.asOfTime.isBefore(since)).toList(),
    );
  }

  @override
  Future<List<ExchangeRate>> querySeriesForPair({
    required String pairKey,
    required DateTime since,
  }) async {
    final series = pairSeries[pairKey] ?? const <ExchangeRate>[];
    return series.where((rate) => !rate.asOfTime.isBefore(since)).toList();
  }

  @override
  Future<ExchangeRate?> queryForDate({
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime date,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<ExchangeRate, AppError>> upsert(ExchangeRate rate) =>
      Future.error(UnimplementedError());
}

class _FakeEventRepository implements EventRepository {
  @override
  Stream<List<DomainEvent>> watchRecent({int limit = 100}) =>
      Stream.value(const <DomainEvent>[]);

  @override
  Stream<List<DomainEvent>> watchByRelated({
    required RelatedModel model,
    required String id,
  }) => Stream.value(const <DomainEvent>[]);

  @override
  Stream<List<DomainEvent>> watchPendingAck({int limit = 100}) =>
      Stream.value(const <DomainEvent>[]);

  @override
  Future<Result<DomainEvent, AppError>> record(DomainEvent event) async => Ok(event);

  @override
  Future<Result<void, AppError>> updateHandling({
    required String id,
    required HandlingStatus status,
    String? handler,
    String? note,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<void, AppError>> updateAck({
    required String id,
    required AckStatus ackStatus,
    String? note,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<void, AppError>> softDelete(String id) =>
      Future.error(UnimplementedError());
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

  testWidgets('shell body swipe switches top-level pages', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/rates');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/rates');

    await _swipeLeft(tester, const Offset(180, 700));
    expect(router.routeInformationProvider.value.uri.toString(), '/cards');
    expect(find.text('还没有卡片'), findsAtLeastNWidgets(1));

    await _swipeRight(tester, const Offset(180, 700));
    expect(router.routeInformationProvider.value.uri.toString(), '/rates');
    expect(find.text('还没有关注的币对'), findsOneWidget);
  });

  testWidgets('vertical drag on rates list does not switch top-level pages', (
    tester,
  ) async {
    final router = await _pumpShell(
      tester,
      initialLocation: '/rates',
      seedRatesList: true,
    );
    await _settleNav(tester);

    expect(find.text('USD/CNY'), findsWidgets);
    expect(router.routeInformationProvider.value.uri.toString(), '/rates');

    await tester.drag(find.byType(ReorderableListView).first, const Offset(18, -280));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/rates');
    expect(find.text('USD/CNY'), findsWidgets);
  });

  testWidgets('holdings deep link restores selected secondary tab', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('分析'), findsWidgets);
    expect(find.text('资产 Top 10'), findsOneWidget);
  });

  testWidgets('events page loads calendar without tabs', (tester) async {
    final router = await _pumpShell(
      tester,
      initialLocation: '/events',
      seedEventCalendar: true,
    );
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events');
    // Tab bar is gone — the calendar fills the page.
    expect(find.text('日历'), findsNothing);
    expect(find.text('待办'), findsNothing);
    expect(find.text('失败'), findsNothing);
  });

  testWidgets('analysis tab drag keeps nested tab state when returning', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('资产 Top 10'), findsOneWidget);

    await tester.drag(find.text('资产 Top 10'), const Offset(-220, 0));
    await _settleNav(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/events');

    await tester.dragFrom(const Offset(180, 700), const Offset(220, 0));
    await _settleNav(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('资产 Top 10'), findsOneWidget);
  });

  testWidgets('leaving events page does not break later shell fallback swipe', (
    tester,
  ) async {
    final router = await _pumpShell(
      tester,
      initialLocation: '/events',
      seedEventCalendar: true,
      seedRatesList: true,
    );
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events');

    await _swipeLeft(tester, const Offset(180, 700));
    expect(router.routeInformationProvider.value.uri.toString(), '/rates');
    expect(find.text('USD/CNY'), findsWidgets);

    await _swipeRight(tester, const Offset(180, 700));
    expect(router.routeInformationProvider.value.uri.toString(), '/events');
  });

  testWidgets('rapid analysis drags do not freeze nested handoff', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    await tester.drag(find.text('资产 Top 10'), const Offset(-220, 0));
    await _settleNav(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/events');

    await tester.dragFrom(const Offset(180, 700), const Offset(220, 0));
    await _settleNav(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');

    await tester.drag(find.text('资产 Top 10'), const Offset(-220, 0));
    await _settleNav(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/events');
  });

  testWidgets('dashboard bills strip drag does not switch top-level pages', (tester) async {
    final router = await _pumpShell(
      tester,
      initialLocation: '/dashboard',
      seedDashboardBills: true,
    );
    await _settleNav(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await _settleNav(tester);

    expect(find.text('即将到来的账单'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.toString(), '/dashboard');

    await tester.drag(find.byType(HorizontalGestureGuard).first, const Offset(-220, 0));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/dashboard');
    expect(find.text('即将到来的账单'), findsOneWidget);
  });

  testWidgets('event calendar swipe changes month without switching page', (tester) async {
    final router = await _pumpShell(
      tester,
      initialLocation: '/events',
      seedEventCalendar: true,
    );
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events');
    // Calendar starts collapsed; expand to reveal month label.
    await tester.tap(find.byTooltip('展开为月视图'));
    await _settleNav(tester);
    expect(find.textContaining('年'), findsWidgets);
    final before = tester.widget<Text>(find.textContaining('年').first).data!;

    // Month grid's guard is now the first (only) one that claims horizontal drag.
    await tester.drag(find.byType(HorizontalGestureGuard).first, const Offset(-220, 0));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events');
    final after = tester.widget<Text>(find.textContaining('年').first).data!;
    expect(after, isNot(before));

    await tester.drag(find.byType(HorizontalGestureGuard).first, const Offset(220, 0));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events');
    final afterBack = tester.widget<Text>(find.textContaining('年').first).data!;
    expect(afterBack, isNot(after));
  });

  testWidgets('holdings analysis horizontal area drag does not switch page', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('维度探索'), findsOneWidget);

    await tester.drag(find.byType(TabBarView).last, const Offset(0, -500));
    await _settleNav(tester);
    expect(find.text('币种敞口热力图'), findsOneWidget);

    await tester.drag(find.byType(HorizontalGestureGuard).last, const Offset(-220, 0));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('币种敞口热力图'), findsOneWidget);

    await tester.drag(find.byType(HorizontalGestureGuard).last, const Offset(220, 0));
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('币种敞口热力图'), findsOneWidget);
  });
}
