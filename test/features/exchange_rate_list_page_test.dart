import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/domain/entities/exchange_rate.dart';
import 'package:gwp/domain/entities/exchange_rate_enums.dart';
import 'package:gwp/domain/entities/watched_pair.dart';
import 'package:gwp/domain/repositories/dict_repository.dart';
import 'package:gwp/domain/repositories/exchange_rate_repository.dart';
import 'package:gwp/domain/repositories/watched_pair_repository.dart';
import 'package:gwp/domain/usecases/manage_watched_pair.dart';
import 'package:gwp/domain/usecases/save_manual_rate.dart';
import 'package:gwp/features/exchange_rate/presentation/exchange_rate_list_page.dart';
import 'package:gwp/features/exchange_rate/presentation/exchange_rate_providers.dart';

void main() {
  testWidgets('汇率录入弹窗使用货币字典选择基准与报价币种', (tester) async {
    final recorder = _RecordingSaveManualRateUseCase();
    await _pumpPage(tester, saveManualRateUseCase: recorder);

    await tester.tap(find.text('录入'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rate-editor-base-currency-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('欧元（EUR）').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rate-editor-quote-currency-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日元（JPY）').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '汇率'), '170.25');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(recorder.invocations, hasLength(1));
    expect(recorder.invocations.single.baseCurrency, 'EUR');
    expect(recorder.invocations.single.quoteCurrency, 'JPY');
  });

  testWidgets('添加币对弹窗使用货币字典选择基准与报价币种', (tester) async {
    final recorder = _RecordingManageWatchedPairUseCase();
    await _pumpPage(tester, manageWatchedPairUseCase: recorder);

    await tester.tap(find.byTooltip('管理币对'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加币对'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pair-editor-base-currency-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('英镑（GBP）').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pair-editor-quote-currency-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('港币（HKD）').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(recorder.addInvocations, hasLength(1));
    expect(recorder.addInvocations.single.baseCurrency, 'GBP');
    expect(recorder.addInvocations.single.quoteCurrency, 'HKD');
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  SaveManualRateUseCase? saveManualRateUseCase,
  ManageWatchedPairUseCase? manageWatchedPairUseCase,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final now = DateTime.utc(2026, 1, 1);
  final currencies = [
    DictEntry(
      id: 1,
      type: DictType.currency,
      code: 'USD',
      name: '美元',
      createdAt: now,
      updatedAt: now,
    ),
    DictEntry(
      id: 2,
      type: DictType.currency,
      code: 'CNY',
      name: '人民币',
      createdAt: now,
      updatedAt: now,
    ),
    DictEntry(
      id: 3,
      type: DictType.currency,
      code: 'EUR',
      name: '欧元',
      createdAt: now,
      updatedAt: now,
    ),
    DictEntry(
      id: 4,
      type: DictType.currency,
      code: 'JPY',
      name: '日元',
      createdAt: now,
      updatedAt: now,
    ),
    DictEntry(
      id: 5,
      type: DictType.currency,
      code: 'GBP',
      name: '英镑',
      createdAt: now,
      updatedAt: now,
    ),
    DictEntry(
      id: 6,
      type: DictType.currency,
      code: 'HKD',
      name: '港币',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchedPairListProvider.overrideWith(
          (ref) => Stream.value(
            [
              WatchedPair(
                pairKey: 'USD/CNY',
                baseCurrency: 'USD',
                quoteCurrency: 'CNY',
                createdAt: now,
              ),
            ],
          ),
        ),
        pairRateSeriesProvider('USD/CNY').overrideWith(
          (ref) => Stream.value(const <ExchangeRate>[]),
        ),
        dictEntriesProvider(DictType.currency).overrideWith(
          (ref) => Stream.value(currencies),
        ),
        if (saveManualRateUseCase != null)
          saveManualRateUseCaseProvider.overrideWithValue(saveManualRateUseCase),
        if (manageWatchedPairUseCase != null)
          manageWatchedPairUseCaseProvider.overrideWithValue(manageWatchedPairUseCase),
      ],
      child: const MaterialApp(home: ExchangeRateListPage()),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _RecordingSaveManualRateUseCase extends SaveManualRateUseCase {
  _RecordingSaveManualRateUseCase()
      : super(
          rates: _NoopExchangeRateRepository(),
          watchedPairs: _RecordingManageWatchedPairUseCase(),
          dicts: _FakeDictRepository(),
          idGenerator: () => 'rate-1',
          now: () => DateTime.utc(2026, 1, 1),
        );

  final invocations = <_ManualRateInvocation>[];

  @override
  Future<Result<ExchangeRate, AppError>> call({
    required String baseCurrency,
    required String quoteCurrency,
    required Decimal rate,
    required SnapshotType snapshotType,
    String source = 'manual',
  }) async {
    invocations.add(
      _ManualRateInvocation(
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        rate: rate,
        snapshotType: snapshotType,
        source: source,
      ),
    );
    return Ok(
      ExchangeRate(
        id: 'rate-1',
        pairKey: '$baseCurrency/$quoteCurrency',
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        rate: rate,
        asOfTime: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        source: source,
        snapshotType: snapshotType,
      ),
    );
  }
}

class _ManualRateInvocation {
  const _ManualRateInvocation({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.snapshotType,
    required this.source,
  });

  final String baseCurrency;
  final String quoteCurrency;
  final Decimal rate;
  final SnapshotType snapshotType;
  final String source;
}

class _RecordingManageWatchedPairUseCase extends ManageWatchedPairUseCase {
  _RecordingManageWatchedPairUseCase()
      : super(_NoopWatchedPairRepository(), _FakeDictRepository());

  final addInvocations = <_PairInvocation>[];

  @override
  Future<Result<WatchedPair, AppError>> add({
    required String baseCurrency,
    required String quoteCurrency,
  }) async {
    addInvocations.add(
      _PairInvocation(baseCurrency: baseCurrency, quoteCurrency: quoteCurrency),
    );
    return Ok(
      WatchedPair(
        pairKey: '$baseCurrency/$quoteCurrency',
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }
}

class _PairInvocation {
  const _PairInvocation({required this.baseCurrency, required this.quoteCurrency});

  final String baseCurrency;
  final String quoteCurrency;
}

class _NoopExchangeRateRepository implements ExchangeRateRepository {
  @override
  Future<Result<ExchangeRate, AppError>> latestFor({
    required String baseCurrency,
    required String quoteCurrency,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ExchangeRate?> queryForDate({
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime date,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ExchangeRate>> querySeriesForPair({
    required String pairKey,
    required DateTime since,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ExchangeRate, AppError>> upsert(ExchangeRate rate) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ExchangeRate>> watchAll({int limit = 200}) => const Stream.empty();

  @override
  Stream<List<ExchangeRate>> watchSeriesForPair({
    required String pairKey,
    required DateTime since,
  }) => const Stream.empty();
}

class _NoopWatchedPairRepository implements WatchedPairRepository {
  @override
  Future<Result<WatchedPair, AppError>> add({
    required String baseCurrency,
    required String quoteCurrency,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WatchedPair>> listAll() {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> remove(String pairKey) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> updateThresholds({
    required String pairKey,
    required Decimal? thresholdHigh,
    required Decimal? thresholdLow,
    required Decimal? alertChangePct,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<WatchedPair>> watchAll() => const Stream.empty();
}

class _FakeDictRepository implements DictRepository {
  static const _codes = {'USD', 'CNY', 'EUR', 'JPY', 'GBP', 'HKD'};

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
    if (type != DictType.currency || !_codes.contains(normalized)) return null;
    return DictEntry(
      id: _codes.toList().indexOf(normalized) + 1,
      type: type,
      code: normalized,
      name: normalized,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
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
