import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/dict_providers.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/domain/repositories/channel_repository.dart';
import 'package:gwp/domain/repositories/dict_repository.dart';
import 'package:gwp/domain/usecases/save_channel.dart';
import 'package:gwp/features/channel/presentation/channel_form.dart';
import 'package:gwp/features/channel/presentation/channel_providers.dart';

void main() {
  testWidgets('通道表单使用字典多选保存地区规则', (tester) async {
    final now = DateTime.utc(2026, 1, 1);
    final repo = _CapturingChannelRepository();
    final entries = [
      DictEntry(
        id: 1,
        type: DictType.sovereigntyRegion,
        code: 'CN',
        name: '中国',
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 2,
        type: DictType.sovereigntyRegion,
        code: 'HK',
        name: '中国香港',
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 3,
        type: DictType.sovereigntyRegion,
        code: 'IR',
        name: '伊朗',
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 4,
        type: DictType.transferProtocol,
        code: 'SWIFT',
        name: '环球银行金融电信协会',
        nameEn: 'Society for Worldwide Interbank Financial Telecommunication',
        isBuiltin: true,
        createdAt: now,
        updatedAt: now,
      ),
      DictEntry(
        id: 5,
        type: DictType.transferProtocol,
        code: 'FPS',
        name: '快速支付系统',
        nameEn: 'Faster Payment System',
        isBuiltin: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictEntriesProvider(DictType.sovereigntyRegion).overrideWith(
            (ref) => Stream.value(entries.where((e) => e.type == DictType.sovereigntyRegion).toList()),
          ),
          dictEntriesProvider(DictType.transferProtocol).overrideWith(
            (ref) => Stream.value(entries.where((e) => e.type == DictType.transferProtocol).toList()),
          ),
          dictEntriesProvider(DictType.currency).overrideWith(
            (ref) => Stream.value(const <DictEntry>[]),
          ),
          saveChannelUseCaseProvider.overrideWithValue(
            SaveChannelUseCase(repo, _FakeDictRepository(entries)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ChannelForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('环球银行金融电信协会（SWIFT）'), findsOneWidget);
    expect(find.text('内置'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextFormField, '通道名称'), 'SWIFT');

    await tester.ensureVisible(find.byKey(const Key('channel-allowed-regions-field')));
    await tester.tap(find.byKey(const Key('channel-allowed-regions-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '中国'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '中国香港'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '完成').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('channel-blocked-regions-field')));
    await tester.tap(find.byKey(const Key('channel-blocked-regions-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '伊朗'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '完成').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('channel-require-same-region-switch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('channel-require-same-region-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.saved, isNotNull);
    expect(repo.saved!.sovereigntyRegionRule, {
      'allowedRegions': ['CN', 'HK'],
      'blockedRegions': ['IR'],
      'requireSameRegion': true,
    });
  });
}

class _CapturingChannelRepository implements ChannelRepository {
  Channel? saved;

  @override
  Future<Result<Channel, AppError>> findById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> setStatus(String id, ChannelStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Channel, AppError>> upsert(Channel channel) async {
    saved = channel;
    return Ok(channel);
  }

  @override
  Stream<List<Channel>> watchAll() => const Stream.empty();

  @override
  Future<Result<void, AppError>> reorder(List<String> channelIds) {
    throw UnimplementedError();
  }
}

class _FakeDictRepository implements DictRepository {
  _FakeDictRepository(this.entries);

  final List<DictEntry> entries;

  @override
  Future<Result<DictEntry, AppError>> addCustom({required DictType type, required String code, required String name, String? nameEn, int sortOrder = 1000, String? flagEmoji, String? continent, String? colorHex, double? mapLon, double? mapLat, double? anchorLon, double? anchorLat, String? parentRegion}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, AppError>> deleteCustom(int id) {
    throw UnimplementedError();
  }

  @override
  Future<DictEntry?> findByTypeAndCode(DictType type, String code) async {
    final normalized = code.trim().toUpperCase();
    for (final entry in entries) {
      if (entry.type == type && entry.code == normalized) return entry;
    }
    return null;
  }

  @override
  Future<List<DictEntry>> listByType(DictType type) async =>
      entries.where((e) => e.type == type).toList(growable: false);

  @override
  Future<Result<DictEntry, AppError>> updateEntry({required int id, String? name, String? nameEn, int? sortOrder, Object? flagEmoji = const _Absent(), Object? continent = const _Absent(), Object? colorHex = const _Absent(), Object? mapLon = const _Absent(), Object? mapLat = const _Absent(), Object? anchorLon = const _Absent(), Object? anchorLat = const _Absent(), Object? parentRegion = const _Absent()}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<DictEntry>> watchByType(DictType type) async* {
    yield await listByType(type);
  }

  @override
  Future<Result<void, AppError>> reorderByType(DictType type, List<int> entryIds) {
    throw UnimplementedError();
  }
}

class _Absent {
  const _Absent();
}
