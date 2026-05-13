import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/core/ui/region_meta.dart';
import 'package:gwp/core/valuation/valuation_currency_provider.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/usecases/value_assets_in_currency.dart';
import 'package:gwp/features/account/presentation/account_providers.dart';
import 'package:gwp/features/asset/presentation/asset_list_page.dart';
import 'package:gwp/features/asset/presentation/asset_providers.dart';

void main() {
  Future<void> pumpAssetList(
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
          valuationCurrencyProvider.overrideWith(() => ValuationCurrencyNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AssetListBody()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> scrollToFinder(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToText(WidgetTester tester, String text) async {
    await scrollToFinder(tester, find.text(text));
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
    required AssetType type,
    required Decimal marketValue,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Asset(
      id: id,
      accountId: accountId,
      assetType: type,
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
    required AssetType type,
    required Decimal marketValue,
  }) {
    final asset = buildAsset(
      id: id,
      accountId: accountId,
      type: type,
      marketValue: marketValue,
    );
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

  testWidgets('renders nested region, account-type, and account groups in value order', (
    tester,
  ) async {
    final accounts = [
      buildAccount(id: 'gb-bank-1', type: AccountType.bank, region: 'GB', name: 'HSBC'),
      buildAccount(id: 'gb-bank-2', type: AccountType.bank, region: 'GB', name: 'Barclays'),
      buildAccount(id: 'gb-broker-1', type: AccountType.broker, region: 'GB', name: 'IBKR UK'),
      buildAccount(id: 'us-bank-1', type: AccountType.bank, region: 'US', name: 'Chase'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'a1', accountId: 'gb-bank-1', type: AssetType.stock, marketValue: Decimal.fromInt(700)),
      buildValuedAsset(id: 'a2', accountId: 'gb-bank-2', type: AssetType.fund, marketValue: Decimal.fromInt(500)),
      buildValuedAsset(id: 'a3', accountId: 'gb-broker-1', type: AssetType.stock, marketValue: Decimal.fromInt(400)),
      buildValuedAsset(id: 'a4', accountId: 'us-bank-1', type: AssetType.bond, marketValue: Decimal.fromInt(300)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
      'US': const RegionMeta(code: 'US', displayName: '美国'),
    };

    await pumpAssetList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    // Regions start collapsed; expand to reveal sub-groups.
    await tester.tap(find.text('英国 (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('美国 (1)'));
    await tester.pumpAndSettle();

    expect(find.text('英国 (3)'), findsOneWidget);
    expect(find.text('美国 (1)'), findsOneWidget);
    expect(find.text('银行 (2)'), findsOneWidget);
    expect(find.text('券商 (1)'), findsOneWidget);
    expect(find.text('HSBC (1)'), findsOneWidget);
    expect(find.text('Barclays (1)'), findsOneWidget);
    expect(find.text('IBKR UK (1)'), findsOneWidget);

    final ukTopLeft = tester.getTopLeft(find.text('英国 (3)'));
    final usTopLeft = tester.getTopLeft(find.text('美国 (1)'));
    expect(ukTopLeft.dy, lessThan(usTopLeft.dy));

    final bankTopLeft = tester.getTopLeft(find.text('银行 (2)'));
    final brokerTopLeft = tester.getTopLeft(find.text('券商 (1)'));
    expect(bankTopLeft.dy, lessThan(brokerTopLeft.dy));

    final hsbcTopLeft = tester.getTopLeft(find.text('HSBC (1)'));
    final barclaysTopLeft = tester.getTopLeft(find.text('Barclays (1)'));
    expect(hsbcTopLeft.dy, lessThan(barclaysTopLeft.dy));
  });

  testWidgets('collapsing a region hides subgroup headers account headers and asset cards', (
    tester,
  ) async {
    final accounts = [
      buildAccount(id: 'gb-bank-1', type: AccountType.bank, region: 'GB', name: 'HSBC'),
      buildAccount(id: 'gb-broker-1', type: AccountType.broker, region: 'GB', name: 'IBKR UK'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'b1', accountId: 'gb-bank-1', type: AssetType.stock, marketValue: Decimal.fromInt(600)),
      buildValuedAsset(id: 'b2', accountId: 'gb-broker-1', type: AssetType.bond, marketValue: Decimal.fromInt(300)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
    };

    await pumpAssetList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    // Expand the region first.
    await tester.tap(find.text('英国 (2)'));
    await tester.pumpAndSettle();

    expect(find.text('银行 (1)'), findsOneWidget);
    expect(find.text('HSBC (1)'), findsOneWidget);
    expect(find.text('b1'), findsOneWidget);

    await tester.tap(find.text('英国 (2)'));
    await tester.pumpAndSettle();

    expect(find.text('银行 (1)'), findsNothing);
    expect(find.text('HSBC (1)'), findsNothing);
    expect(find.text('b1'), findsNothing);
  });

  testWidgets('renders all grouped accounts and assets by default', (
    tester,
  ) async {
    final accounts = [
      buildAccount(id: 'gb-bank-1', type: AccountType.bank, region: 'GB', name: 'HSBC'),
      buildAccount(id: 'gb-bank-2', type: AccountType.bank, region: 'GB', name: 'Barclays'),
      buildAccount(id: 'gb-bank-3', type: AccountType.bank, region: 'GB', name: 'Lloyds'),
      buildAccount(id: 'gb-bank-4', type: AccountType.bank, region: 'GB', name: 'NatWest'),
      buildAccount(id: 'gb-broker-1', type: AccountType.broker, region: 'GB', name: 'IBKR UK'),
    ];
    final valuedAssets = [
      buildValuedAsset(id: 'c1', accountId: 'gb-bank-1', type: AssetType.stock, marketValue: Decimal.fromInt(500)),
      buildValuedAsset(id: 'c2', accountId: 'gb-bank-1', type: AssetType.fund, marketValue: Decimal.fromInt(400)),
      buildValuedAsset(id: 'c3', accountId: 'gb-bank-1', type: AssetType.bond, marketValue: Decimal.fromInt(300)),
      buildValuedAsset(id: 'c4', accountId: 'gb-bank-1', type: AssetType.cd, marketValue: Decimal.fromInt(200)),
      buildValuedAsset(id: 'c5', accountId: 'gb-bank-2', type: AssetType.stock, marketValue: Decimal.fromInt(190)),
      buildValuedAsset(id: 'c6', accountId: 'gb-bank-3', type: AssetType.stock, marketValue: Decimal.fromInt(180)),
      buildValuedAsset(id: 'c7', accountId: 'gb-bank-4', type: AssetType.stock, marketValue: Decimal.fromInt(170)),
      buildValuedAsset(id: 'c8', accountId: 'gb-broker-1', type: AssetType.stock, marketValue: Decimal.fromInt(160)),
    ];
    final regionIndex = <String, RegionMeta>{
      'GB': const RegionMeta(code: 'GB', displayName: '英国'),
    };

    await pumpAssetList(
      tester,
      accounts: accounts,
      valuedAssets: valuedAssets,
      regionIndex: regionIndex,
    );

    await tester.tap(find.text('英国 (5)'));
    await tester.pumpAndSettle();

    expect(find.text('HSBC (4)'), findsOneWidget);
    expect(find.text('Barclays (1)'), findsOneWidget);
    expect(find.text('Lloyds (1)'), findsOneWidget);
    await scrollToText(tester, 'NatWest (1)');
    expect(find.text('NatWest (1)'), findsOneWidget);
    expect(find.text('IBKR UK (1)'), findsOneWidget);
    expect(find.text('c1'), findsOneWidget);
    expect(find.text('c2'), findsOneWidget);
    expect(find.text('c3'), findsOneWidget);
    expect(find.text('c4'), findsOneWidget);
    expect(find.textContaining('展开剩余'), findsNothing);
  });
}
