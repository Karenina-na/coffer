import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:coffer/core/ui/region_meta.dart';
import 'package:coffer/data/providers/dict_providers.dart';
import 'package:coffer/domain/entities/account.dart';
import 'package:coffer/domain/entities/account_channel.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/channel.dart';
import 'package:coffer/domain/entities/channel_enums.dart';
import 'package:coffer/domain/entities/dict_entry.dart';
import 'package:coffer/domain/entities/dict_type.dart';
import 'package:coffer/features/account/presentation/account_providers.dart';
import 'package:coffer/features/asset/presentation/asset_providers.dart';
import 'package:coffer/features/channel/presentation/channel_list_page.dart';
import 'package:coffer/features/channel/presentation/channel_providers.dart';
import 'package:coffer/features/channel/presentation/transfer_simulate_page.dart';
import 'package:coffer/features/exchange_rate/presentation/exchange_rate_providers.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: TransferSimulateBody()),
    ),
    GoRoute(path: '/channels', builder: (_, _) => const ChannelListPage()),
  ],
);

Future<void> _pumpTransfer(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final now = DateTime.utc(2026, 1, 1);
  final accounts = [
    Account(
      id: 'acc-1',
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'ICBC',
      status: AccountStatus.active,
      fxSpreadPercent: Decimal.zero,
      createdAt: now,
      updatedAt: now,
    ),
    Account(
      id: 'acc-2',
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'Fidelity',
      status: AccountStatus.active,
      fxSpreadPercent: Decimal.zero,
      createdAt: now,
      updatedAt: now,
    ),
    Account(
      id: 'acc-3',
      accountType: AccountType.payment,
      sovereigntyRegion: 'SG',
      institutionName: 'Unlinked Wallet',
      status: AccountStatus.active,
      fxSpreadPercent: Decimal.zero,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final channels = [
    Channel(
      id: 'ch-1',
      name: '环球银行金融电信协会通道',
      transferProtocol: 'SWIFT',
      isBuiltin: true,
      status: ChannelStatus.enabled,
      createdAt: now,
      updatedAt: now,
    ),
    Channel(
      id: 'ch-2',
      name: '美国自动清算所通道',
      transferProtocol: 'ACH',
      isBuiltin: true,
      status: ChannelStatus.enabled,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final links = [
    AccountChannel(accountId: 'acc-1', channelId: 'ch-1', createdAt: now),
    AccountChannel(accountId: 'acc-2', channelId: 'ch-2', createdAt: now),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountListProvider.overrideWith((ref) => Stream.value(accounts)),
        assetListProvider.overrideWith((ref) => Stream.value(const [])),
        accountChannelListProvider.overrideWith((ref) => Stream.value(links)),
        channelListProvider.overrideWith((ref) => Stream.value(channels)),
        regionMetaIndexProvider.overrideWith(
          (ref) => Stream.value(<String, RegionMeta>{}),
        ),
        exchangeRateListProvider.overrideWith((ref) => Stream.value(const [])),
        dictEntriesProvider(
          DictType.currency,
        ).overrideWith((ref) => Stream.value(<DictEntry>[])),
        dictEntriesProvider(DictType.transferProtocol).overrideWith(
          (ref) => Stream.value([
            DictEntry(
              id: 1,
              type: DictType.transferProtocol,
              code: 'SWIFT',
              name: '环球银行金融电信协会',
              nameEn:
                  'Society for Worldwide Interbank Financial Telecommunication',
              isBuiltin: true,
              createdAt: now,
              updatedAt: now,
            ),
            DictEntry(
              id: 2,
              type: DictType.transferProtocol,
              code: 'ACH',
              name: '美国自动清算所',
              nameEn: 'Automated Clearing House',
              isBuiltin: true,
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('转账页顶部展示通道摘要并可进入通道管理', (tester) async {
    await _pumpTransfer(tester);

    expect(find.text('通道管理'), findsOneWidget);

    await tester.tap(find.text('通道管理'));
    await tester.pumpAndSettle();

    expect(find.text('转账通道'), findsOneWidget);
    expect(find.text('环球银行金融电信协会通道'), findsOneWidget);
    expect(find.text('内置'), findsWidgets);
  });

  testWidgets('源账户选择改为底部弹窗并默认过滤未接入通道账户', (tester) async {
    await _pumpTransfer(tester);

    await tester.tap(find.text('选择源账户'));
    await tester.pumpAndSettle();

    expect(find.text('选择源账户'), findsWidgets);
    expect(find.text('已接入通道'), findsOneWidget);
    expect(find.text('ICBC'), findsOneWidget);
    expect(find.text('Fidelity'), findsOneWidget);
    expect(find.text('Unlinked Wallet'), findsNothing);
  });
}
