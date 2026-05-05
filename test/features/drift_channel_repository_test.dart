import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_channel_repository.dart';
import 'package:gwp/domain/entities/channel.dart';
import 'package:gwp/domain/entities/channel_enums.dart';

void main() {
  late AppDatabase db;
  late DriftChannelRepository repo;

  final now = DateTime.utc(2025, 6, 15);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftChannelRepository(db.channelDao, now: () => now);
  });

  tearDown(() => db.close());

  Channel makeChannel({String id = 'ch-1', ChannelStatus status = ChannelStatus.enabled}) {
    return Channel(
      id: id,
      name: 'SWIFT',
      transferProtocol: 'SWIFT',
      feeRate: Decimal.parse('0.001'),
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('upsert and findById round-trip', () async {
    final ch = makeChannel();
    await repo.upsert(ch);

    final r = await repo.findById('ch-1');
    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.name, 'SWIFT');
    expect(r.valueOrNull!.status, ChannelStatus.enabled);
  });

  test('findById returns NotFoundError for missing id', () async {
    final r = await repo.findById('nonexistent');
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('upsert updates existing channel', () async {
    final ch = makeChannel();
    await repo.upsert(ch);

    final updated = ch.copyWith(name: 'SWIFT-UPDATED', updatedAt: now);
    await repo.upsert(updated);

    final r = await repo.findById('ch-1');
    expect(r.valueOrNull!.name, 'SWIFT-UPDATED');
  });

  test('setStatus updates status', () async {
    await repo.upsert(makeChannel());

    final r = await repo.setStatus('ch-1', ChannelStatus.disabled);
    expect(r.isOk, isTrue);

    final found = await repo.findById('ch-1');
    expect(found.valueOrNull!.status, ChannelStatus.disabled);
  });

  test('setStatus returns NotFoundError for missing id', () async {
    final r = await repo.setStatus('nonexistent', ChannelStatus.disabled);
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('watchAll emits all channels ordered by createdAt desc', () async {
    final t1 = DateTime.utc(2025, 6, 14);
    final t2 = DateTime.utc(2025, 6, 15);
    await repo.upsert(makeChannel(id: 'ch-1').copyWith(createdAt: t1, updatedAt: t1));
    await repo.upsert(makeChannel(id: 'ch-2').copyWith(createdAt: t2, updatedAt: t2));

    final list = await repo.watchAll().first;
    expect(list.length, 2);
    // newest first
    expect(list.first.id, 'ch-2');
  });
}
