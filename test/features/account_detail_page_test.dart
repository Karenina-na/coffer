import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_channel.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';
import 'package:gwp/domain/usecases/value_assets_in_currency.dart';
import 'package:gwp/features/account/presentation/account_detail_page.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/asset/presentation/asset_providers.dart';
import 'package:gwp/features/card/presentation/card_by_account_providers.dart';
import 'package:gwp/features/channel/presentation/channel_providers.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/accounts/acc-1',
      routes: [
        GoRoute(
          path: '/accounts/:id',
          builder: (_, state) =>
              AccountDetailPage(accountId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/channels/:id',
          builder: (_, state) => Scaffold(
            body: Center(child: Text('CHANNEL:${state.pathParameters['id']}')),
          ),
        ),
      ],
    );

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final now = DateTime.utc(2026, 1, 1);
  final account = Account(
    id: 'acc-1',
    accountType: AccountType.bank,
    sovereigntyRegion: 'CN',
    institutionName: 'ICBC',
    status: AccountStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  final channel = Channel(
    id: 'ch-1',
    name: 'SWIFT Main',
    transferProtocol: 'SWIFT',
    status: ChannelStatus.enabled,
    createdAt: now,
    updatedAt: now,
  );
  final link = AccountChannel(
    accountId: 'acc-1',
    channelId: 'ch-1',
    createdAt: now,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountListProvider.overrideWith((ref) => Stream.value([account])),
        assetsByAccountProvider('acc-1').overrideWith((ref) => Stream.value(const [])),
        valuedAssetsByAccountProvider('acc-1').overrideWith(
          (ref) async => ValuedAssets(
            valuationCurrency: 'CNY',
            assets: [],
            total: Decimal.zero,
            missingAssetIds: [],
          ),
        ),
        cardsByAccountProvider('acc-1').overrideWith((ref) => Stream.value(const [])),
        accountChannelsByAccountProvider('acc-1').overrideWith((ref) => Stream.value([link])),
        channelListProvider.overrideWith((ref) => Stream.value([channel])),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('账户详情页通道卡片点击信息区可进入通道详情', (tester) async {
    await _pumpPage(tester);

    expect(find.text('SWIFT Main'), findsOneWidget);
    await tester.tap(find.text('SWIFT Main'));
    await tester.pumpAndSettle();

    expect(find.text('CHANNEL:ch-1'), findsOneWidget);
  });
}
