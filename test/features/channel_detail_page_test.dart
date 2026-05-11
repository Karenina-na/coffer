import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_channel.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/channel/presentation/channel_detail_page.dart';
import 'package:gwp/features/channel/presentation/channel_providers.dart';

Future<void> _pumpChannelDetail(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final now = DateTime.utc(2026, 1, 1);
  final channel = Channel(
    id: 'ch-1',
    name: '环球银行金融电信协会通道',
    transferProtocol: 'SWIFT',
    isBuiltin: true,
    feeRate: Decimal.zero,
    fixedFee: Decimal.zero,
    limitCurrency: 'USD',
    status: ChannelStatus.enabled,
    createdAt: now,
    updatedAt: now,
  );
  final accounts = [
    Account(
      id: 'acc-1',
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'ICBC',
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    ),
    Account(
      id: 'acc-2',
      accountType: AccountType.broker,
      sovereigntyRegion: 'US',
      institutionName: 'Fidelity',
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final links = [
    AccountChannel(
      accountId: 'acc-1',
      channelId: 'ch-1',
      createdAt: now,
    ),
    AccountChannel(
      accountId: 'acc-2',
      channelId: 'ch-1',
      feeRateOverride: Decimal.zero,
      fixedFeeOverride: Decimal.zero,
      feeCurrencyOverride: 'USD',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelListProvider.overrideWith((ref) => Stream.value([channel])),
        accountChannelListProvider.overrideWith((ref) => Stream.value(links)),
        accountListProvider.overrideWith((ref) => Stream.value(accounts)),
        dictEntriesProvider(DictType.transferProtocol).overrideWith(
          (ref) => Stream.value([
            DictEntry(
              id: 1,
              type: DictType.transferProtocol,
              code: 'SWIFT',
              name: '环球银行金融电信协会',
              nameEn: 'Society for Worldwide Interbank Financial Telecommunication',
              isBuiltin: true,
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
      ],
      child: const MaterialApp(
        home: ChannelDetailPage(channelId: 'ch-1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('通道详情页显示内置标记与协议中文名', (tester) async {
    await _pumpChannelDetail(tester);

    expect(find.text('环球银行金融电信协会通道'), findsOneWidget);
    expect(find.text('环球银行金融电信协会（SWIFT） · 启用'), findsOneWidget);
    expect(find.text('内置'), findsOneWidget);
  });

  testWidgets('成员账户区块展示默认与账户级费率覆盖状态', (tester) async {
    await _pumpChannelDetail(tester);

    expect(find.text('接入账户 (2)'), findsOneWidget);
    expect(find.text('沿用通道默认费率：免费'), findsOneWidget);
    expect(find.text('账户费率覆盖：免费'), findsOneWidget);
    expect(find.text('默认'), findsOneWidget);
    expect(find.text('已覆盖'), findsOneWidget);
  });
}
