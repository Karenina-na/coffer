import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/core/ui/region_meta.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/usecases/value_assets_in_currency.dart';
import 'package:gwp/features/account/presentation/account_list_page.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/asset/presentation/asset_providers.dart';

void main() {
  Future<void> pumpAccountList(
    WidgetTester tester, {
    required List<Account> accounts,
    required List<ValuedAsset> valuedAssets,
    required RegionIndex regionIndex,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountListProvider.overrideWith((ref) => Stream.value(accounts)),
          valuedAssetsProvider.overrideWith(
            (ref) async => ValuedAssets(
              valuationCurrency: 'USD',
              assets: valuedAssets,
              total: valuedAssets.fold(
                Decimal.zero,
                (sum, asset) => sum + (asset.valuedAmount ?? Decimal.zero),
              ),
              missingAssetIds: const [],
            ),
          ),
          regionMetaIndexProvider.overrideWith((ref) => Stream.value(regionIndex)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountListBody()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> scrollToText(WidgetTester tester, String text) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  Account buildAccount({
    required String id,
    required AccountType type,
    required String region,
    required String name,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Account(
      id: id,
      accountType: type,
      sovereigntyRegion: region,
      institutionName: name,
      status: AccountStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  Asset buildAsset({
    required String id,
    required String accountId,
    required Decimal marketValue,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Asset(
      id: id,
      accountId: accountId,
      assetType: AssetType.stock,
      assetCode: id,
      quantity: Decimal.one,
      currentPrice: marketValue,
      marketValue: marketValue,
      currency: 'USD',
      status: AssetStatus.holding,
      createdAt: now,
      updatedAt: now,
    );
  }

  ValuedAsset buildValuedAsset({
    required String id,
    required String accountId,
    required Decimal marketValue,
  }) {
    final asset = buildAsset(id: id, accountId: accountId, marketValue: marketValue);
    return ValuedAsset(
      asset: asset,
      valuationCurrency: 'USD',
      nativeValue: marketValue,
      valuedAmount: marketValue,
      nativeCostBasis: marketValue,
      valuedCostBasis: marketValue,
      conversionRate: Decimal.one,
      isConvertible: true,
    );
  }

  testWidgets('renders nested region and account-type groups in value order', (
    tester,
  ) async {
    final accounts = [
      buildAccount(id: 'gb-bank', type: AccountType.bank, region: 'GB', name: 'HSBC'),
      buildAccount(id: 'gb-broker', type: AccountType.broker, region: 'GB', name: 'IBKR UK'),
      buildAccount(id: 'us-bank', type: AccountType.bank, region: 'US', name: 'Chase'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'a1', accountId: 'gb-bank', marketValue: Decimal.fromInt(1000)),
      buildValuedAsset(id: 'a2', accountId: 'gb-broker', marketValue: Decimal.fromInt(600)),
      buildValuedAsset(id: 'a3', accountId: 'us-bank', marketValue: Decimal.fromInt(500)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
      'US': const RegionMeta(code: 'US', displayName: '美国'),
    };

    await pumpAccountList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    expect(find.text('英国 (2)'), findsOneWidget);
    expect(find.text('美国 (1)'), findsOneWidget);
    expect(find.text('银行 (1)'), findsNWidgets(2));
    expect(find.text('券商 (1)'), findsOneWidget);

    final ukTopLeft = tester.getTopLeft(find.text('英国 (2)'));
    final usTopLeft = tester.getTopLeft(find.text('美国 (1)'));
    expect(ukTopLeft.dy, lessThan(usTopLeft.dy));

    final bankTopLeft = tester.getTopLeft(find.text('银行 (1)').first);
    final brokerTopLeft = tester.getTopLeft(find.text('券商 (1)'));
    expect(bankTopLeft.dy, lessThan(brokerTopLeft.dy));

    final hsbcTopLeft = tester.getTopLeft(find.text('HSBC'));
    final ibkrTopLeft = tester.getTopLeft(find.text('IBKR UK'));
    expect(hsbcTopLeft.dy, lessThan(ibkrTopLeft.dy));
  });

  testWidgets('show more expands only the current type subgroup', (tester) async {
    final accounts = [
      buildAccount(id: 'gb-bank-1', type: AccountType.bank, region: 'GB', name: 'Bank A'),
      buildAccount(id: 'gb-bank-2', type: AccountType.bank, region: 'GB', name: 'Bank B'),
      buildAccount(id: 'gb-bank-3', type: AccountType.bank, region: 'GB', name: 'Bank C'),
      buildAccount(id: 'gb-bank-4', type: AccountType.bank, region: 'GB', name: 'Bank D'),
      buildAccount(id: 'gb-broker-1', type: AccountType.broker, region: 'GB', name: 'Broker A'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'b1', accountId: 'gb-bank-1', marketValue: Decimal.fromInt(400)),
      buildValuedAsset(id: 'b2', accountId: 'gb-bank-2', marketValue: Decimal.fromInt(300)),
      buildValuedAsset(id: 'b3', accountId: 'gb-bank-3', marketValue: Decimal.fromInt(200)),
      buildValuedAsset(id: 'b4', accountId: 'gb-bank-4', marketValue: Decimal.fromInt(100)),
      buildValuedAsset(id: 'b5', accountId: 'gb-broker-1', marketValue: Decimal.fromInt(50)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
    };

    await pumpAccountList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    expect(find.text('Bank A'), findsOneWidget);
    expect(find.text('Bank B'), findsOneWidget);
    expect(find.text('Bank C'), findsOneWidget);
    expect(find.text('Bank D'), findsNothing);
    await scrollToText(tester, 'Broker A');
    expect(find.text('Broker A'), findsOneWidget);
    await scrollToText(tester, '展开剩余 1 项');
    expect(find.text('展开剩余 1 项'), findsOneWidget);

    await tester.tap(find.text('展开剩余 1 项'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Bank D');
    expect(find.text('Bank D'), findsOneWidget);
    await scrollToText(tester, 'Broker A');
    expect(find.text('Broker A'), findsOneWidget);
  });

  testWidgets('collapsing a region hides subgroup headers and cards', (tester) async {
    final accounts = [
      buildAccount(id: 'gb-bank', type: AccountType.bank, region: 'GB', name: 'HSBC'),
      buildAccount(id: 'gb-broker', type: AccountType.broker, region: 'GB', name: 'IBKR UK'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'c1', accountId: 'gb-bank', marketValue: Decimal.fromInt(1000)),
      buildValuedAsset(id: 'c2', accountId: 'gb-broker', marketValue: Decimal.fromInt(500)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
    };

    await pumpAccountList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    expect(find.text('银行 (1)'), findsOneWidget);
    expect(find.text('券商 (1)'), findsOneWidget);
    expect(find.text('HSBC'), findsOneWidget);

    await tester.tap(find.text('英国 (2)'));
    await tester.pumpAndSettle();

    expect(find.text('银行 (1)'), findsNothing);
    expect(find.text('券商 (1)'), findsNothing);
    expect(find.text('HSBC'), findsNothing);
  });
}
