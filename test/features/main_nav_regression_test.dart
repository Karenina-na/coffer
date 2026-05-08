import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/app/router.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/core/ui/gwp_bar_rank.dart';
import 'package:gwp/core/ui/gwp_radar_chart.dart';
import 'package:gwp/core/ui/region_meta.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/card.dart';
import 'package:gwp/domain/entities/domain_event.dart';
import 'package:gwp/domain/entities/event_enums.dart';
import 'package:gwp/domain/entities/watched_pair.dart';
import 'package:gwp/domain/events/event_bus.dart';
import 'package:gwp/domain/repositories/asset_repository.dart';
import 'package:gwp/domain/repositories/event_repository.dart';
import 'package:gwp/domain/usecases/check_asset_sync_outdated.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/asset/presentation/asset_providers.dart';
import 'package:gwp/features/card/presentation/card_providers.dart';
import 'package:gwp/features/event/presentation/event_providers.dart';
import 'package:gwp/features/exchange_rate/presentation/exchange_rate_providers.dart';
import 'package:gwp/features/holdings/presentation/portfolio_providers.dart';

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

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  String initialLocation = '/rates',
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
          (ref) => Stream.value(const <BankCard>[]),
        ),
        watchedPairListProvider.overrideWith(
          (ref) => Stream.value(const <WatchedPair>[]),
        ),
        unreadEventCountProvider.overrideWith((ref) => 0),
        pendingAckEventsProvider.overrideWith(
          (ref) => Stream.value(const <DomainEvent>[]),
        ),
        recentEventsProvider.overrideWith(
          (ref) => Stream.value(const <DomainEvent>[]),
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
        portfolioSnapshotProvider.overrideWith(
          (ref) async => PortfolioSnapshot(
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
        portfolioByTypeProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        portfolioByCurrencyProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        portfolioByRegionProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        portfolioByInstitutionProvider.overrideWith(
          (ref) async => const <AllocationSlice>[],
        ),
        assetTop10Provider.overrideWith(
          (ref) async => const <RankItem>[],
        ),
        currencyExposureProvider.overrideWith(
          (ref) async => const HeatMatrixData(
            accounts: <String>[],
            currencies: <String>[],
            cells: <(String, String), double>{},
            maxValue: 0,
          ),
        ),
        concentrationProvider.overrideWith(
          (ref) async => const ConcentrationMetrics(
            assetHhi: 0,
            currencyHhi: 0,
            regionHhi: 0,
            top3Share: 0,
            top3Labels: <String>[],
            largestLabel: '-',
            largestShare: 0,
          ),
        ),
        liquidityProvider.overrideWith(
          (ref) async => const LiquidityProfile(
            highValue: 0,
            medValue: 0,
            lowValue: 0,
            total: 0,
          ),
        ),
        healthScoreProvider.overrideWith(
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

    await _swipeLeft(tester, const Offset(180, 300));
    expect(router.routeInformationProvider.value.uri.toString(), '/cards');
    expect(find.text('还没有卡片'), findsAtLeastNWidgets(1));

    await _swipeRight(tester, const Offset(180, 300));
    expect(router.routeInformationProvider.value.uri.toString(), '/rates');
    expect(find.text('还没有关注的币对'), findsOneWidget);
  });

  testWidgets('holdings deep link restores selected secondary tab', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('分析'), findsWidgets);
    expect(find.text('资产 Top 10'), findsOneWidget);
  });

  testWidgets('events deep link restores selected secondary tab', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/events?tab=2');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/events?tab=2');
    expect(find.text('没有失败事件'), findsOneWidget);
  });

  testWidgets('swiping back restores nested tab route state', (tester) async {
    final router = await _pumpShell(tester, initialLocation: '/holdings?tab=3');
    await _settleNav(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('资产 Top 10'), findsOneWidget);

    await _swipeLeft(tester, const Offset(180, 300));
    expect(router.routeInformationProvider.value.uri.toString(), '/events');

    await _swipeRight(tester, const Offset(180, 300));
    expect(router.routeInformationProvider.value.uri.toString(), '/holdings?tab=3');
    expect(find.text('资产 Top 10'), findsOneWidget);
  });
}
