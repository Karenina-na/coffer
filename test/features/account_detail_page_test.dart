import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_channel.dart';
import 'package:gwp/domain/entities/account_enums.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_enums.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/domain/repositories/account_channel_repository.dart';
import 'package:gwp/domain/repositories/account_repository.dart';
import 'package:gwp/domain/repositories/channel_repository.dart';
import 'package:gwp/domain/repositories/dict_repository.dart';
import 'package:gwp/domain/usecases/save_account_channel_config.dart';
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

Future<void> _pumpPage(
  WidgetTester tester, {
  SaveAccountChannelConfigUseCase? saveConfigUseCase,
  List<DictEntry>? currencies,
  List<Asset>? assets,
  bool settle = true,
}) async {
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
  final currencyEntries =
      currencies ??
      [
        DictEntry(
          id: 1,
          type: DictType.currency,
          code: 'USD',
          name: '美元',
          createdAt: now,
          updatedAt: now,
        ),
      ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountListProvider.overrideWith((ref) => Stream.value([account])),
        assetsByAccountProvider('acc-1').overrideWith(
          (ref) => Stream.value(assets ?? const []),
        ),
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
        dictEntriesProvider(DictType.currency).overrideWith(
          (ref) => Stream.value(currencyEntries),
        ),
        if (saveConfigUseCase != null)
          saveAccountChannelConfigUseCaseProvider.overrideWithValue(saveConfigUseCase),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('账户详情页通道卡片点击信息区可进入通道详情', (tester) async {
    await _pumpPage(tester);

    expect(find.text('SWIFT Main'), findsOneWidget);
    await tester.tap(find.text('SWIFT Main'));
    await tester.pumpAndSettle();

    expect(find.text('CHANNEL:ch-1'), findsOneWidget);
  });

  testWidgets('配置费用弹窗可将费用币种覆盖留空表示沿用默认值', (tester) async {
    final recorder = _RecordingSaveAccountChannelConfigUseCase();
    await _pumpPage(
      tester,
      saveConfigUseCase: recorder,
      currencies: [
        DictEntry(
          id: 1,
          type: DictType.currency,
          code: 'USD',
          name: '美元',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        DictEntry(
          id: 2,
          type: DictType.currency,
          code: 'EUR',
          name: '欧元',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    await tester.tap(find.text('配置费用'));
    await tester.pumpAndSettle();

    expect(find.text('费用币种覆盖（可空）'), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-channel-fee-currency-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('沿用通道默认值').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-channel-config-save-button')));
    await tester.pumpAndSettle();

    expect(recorder.invocations, hasLength(1));
    expect(recorder.invocations.single.feeCurrencyOverride, isNull);
  });

  testWidgets('账户详情同步入口展示统一时间窗选项', (tester) async {
    final now = DateTime.utc(2026, 1, 1);
    await _pumpPage(
      tester,
      assets: [
        Asset(
          id: 'ast-1',
          accountId: 'acc-1',
          assetType: AssetType.stock,
          assetCode: 'AAPL',
          quantity: Decimal.fromInt(1),
          currency: 'USD',
          status: AssetStatus.holding,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      settle: false,
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('同步当前账户资产'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('8日'), findsOneWidget);
    expect(find.text('1个月'), findsOneWidget);
    expect(find.text('1年'), findsOneWidget);
    expect(find.text('5年'), findsOneWidget);
  });
}

class _RecordingSaveAccountChannelConfigUseCase
    extends SaveAccountChannelConfigUseCase {
  _RecordingSaveAccountChannelConfigUseCase()
      : super(
          _NoopAccountChannelRepository(),
          _NoopAccountRepository(),
          _NoopChannelRepository(),
          _FakeDictRepository(),
        );

  final invocations = <_SaveConfigInvocation>[];

  @override
  Future<Result<AccountChannel, AppError>> call({
    required String accountId,
    required String channelId,
    Decimal? feeRateOverride,
    Decimal? fixedFeeOverride,
    String? feeCurrencyOverride,
  }) async {
    invocations.add(
      _SaveConfigInvocation(
        accountId: accountId,
        channelId: channelId,
        feeRateOverride: feeRateOverride,
        fixedFeeOverride: fixedFeeOverride,
        feeCurrencyOverride: feeCurrencyOverride,
      ),
    );
    return Ok(
      AccountChannel(
        accountId: accountId,
        channelId: channelId,
        feeRateOverride: feeRateOverride,
        fixedFeeOverride: fixedFeeOverride,
        feeCurrencyOverride: feeCurrencyOverride,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }
}

class _SaveConfigInvocation {
  const _SaveConfigInvocation({
    required this.accountId,
    required this.channelId,
    required this.feeRateOverride,
    required this.fixedFeeOverride,
    required this.feeCurrencyOverride,
  });

  final String accountId;
  final String channelId;
  final Decimal? feeRateOverride;
  final Decimal? fixedFeeOverride;
  final String? feeCurrencyOverride;
}

class _NoopAccountChannelRepository implements AccountChannelRepository {
  @override
  Future<Result<AccountChannel, AppError>> link({
    required String accountId,
    required String channelId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<AccountChannel>, AppError>> listByChannel(String channelId) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> replaceForAccount({
    required String accountId,
    required List<String> channelIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<AccountChannel, AppError>> saveConfig({
    required String accountId,
    required String channelId,
    Decimal? feeRateOverride,
    Decimal? fixedFeeOverride,
    String? feeCurrencyOverride,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> unlink({
    required String accountId,
    required String channelId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AccountChannel>> watchAll() => const Stream.empty();

  @override
  Stream<List<AccountChannel>> watchByAccount(String accountId) =>
      const Stream.empty();
}

class _NoopAccountRepository implements AccountRepository {
  @override
  Future<Result<Account, AppError>> create(Account account) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Account, AppError>> findById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Account, AppError>> update(Account account) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> updateStatus(String id, AccountStatus status) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Account>> watchAll() => const Stream.empty();

  @override
  Stream<Account?> watchById(String id) => const Stream.empty();
}

class _NoopChannelRepository implements ChannelRepository {
  @override
  Future<Result<Channel, AppError>> findById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> setStatus(String id, ChannelStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Channel, AppError>> upsert(Channel channel) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Channel>> watchAll() => const Stream.empty();
}

class _FakeDictRepository implements DictRepository {
  @override
  Future<Result<DictEntry, AppError>> addCustom({required DictType type, required String code, required String name, String? nameEn, int sortOrder = 1000, String? flagEmoji, String? continent, String? colorHex, double? mapLon, double? mapLat, String? parentRegion}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> deleteCustom(int id) {
    throw UnimplementedError();
  }

  @override
  Future<DictEntry?> findByTypeAndCode(DictType type, String code) async {
    final normalized = code.trim().toUpperCase();
    if (type != DictType.currency) return null;
    if (normalized == 'USD' || normalized == 'EUR') {
      return DictEntry(
        id: normalized == 'USD' ? 1 : 2,
        type: type,
        code: normalized,
        name: normalized,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }
    return null;
  }

  @override
  Future<List<DictEntry>> listByType(DictType type) async => const [];

  @override
  Future<Result<DictEntry, AppError>> updateEntry({required int id, String? name, String? nameEn, int? sortOrder, Object? flagEmoji = const _Absent(), Object? continent = const _Absent(), Object? colorHex = const _Absent(), Object? mapLon = const _Absent(), Object? mapLat = const _Absent(), Object? parentRegion = const _Absent()}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<DictEntry>> watchByType(DictType type) => const Stream.empty();
}

class _Absent {
  const _Absent();
}
