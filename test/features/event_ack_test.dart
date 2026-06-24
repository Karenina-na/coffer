import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_event_repository.dart';
import 'package:coffer/domain/entities/domain_event.dart';
import 'package:coffer/domain/entities/event_enums.dart';
import 'package:coffer/domain/usecases/ack_event.dart';

void main() {
  late AppDatabase db;
  late DriftEventRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftEventRepository(db.eventDao);
  });

  tearDown(() => db.close());

  DomainEvent mkEvent({
    String id = 'e1',
    String? sourceKey,
    AckRequirement req = AckRequirement.required_,
    AckStatus ack = AckStatus.pending,
  }) {
    final now = DateTime.utc(2025, 1, 1, 12);
    return DomainEvent(
      id: id,
      eventType: 'TEST_EVENT',
      relatedModel: RelatedModel.account,
      relatedId: 'acc-1',
      triggerTime: now,
      status: EventStatus.triggered,
      ackRequirement: req,
      ackStatus: ack,
      sourceKey: sourceKey,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('record 同 sourceKey 不会重复写入', () async {
    final e1 = mkEvent(id: 'e1', sourceKey: 'k');
    final e2 = mkEvent(id: 'e2', sourceKey: 'k');
    final r1 = await repo.record(e1);
    final r2 = await repo.record(e2);
    expect(r1.isOk, isTrue);
    expect(r2.isOk, isTrue);
    // 第二次返回已有行（id = e1），而不是新写入 e2
    expect(r2.valueOrNull!.id, 'e1');
  });

  test('AckEventUseCase.confirm 写入 ackStatus + ackAt', () async {
    await repo.record(mkEvent(id: 'e-ack'));
    final useCase = AckEventUseCase(repo);
    final r = await useCase.confirm('e-ack', note: '对账一致');
    expect(r.isOk, isTrue);

    final list = await repo.watchRecent().first;
    final found = list.firstWhere((x) => x.id == 'e-ack');
    expect(found.ackStatus, AckStatus.confirmed);
    expect(found.ackAt, isNotNull);
    expect(found.ackNote, '对账一致');
  });

  test('watchPendingAck 只返回 REQUIRED + PENDING', () async {
    await repo.record(mkEvent(id: 'pending'));
    await repo.record(mkEvent(
      id: 'optional',
      req: AckRequirement.optional,
    ));
    await repo.record(mkEvent(
      id: 'confirmed',
      ack: AckStatus.confirmed,
    ));
    await repo.record(mkEvent(
      id: 'na',
      req: AckRequirement.notApplicable,
    ));

    final list = await repo.watchPendingAck().first;
    expect(list.map((e) => e.id).toList(), ['pending']);
  });

  test('softDelete 从 watchRecent 中隐藏', () async {
    await repo.record(mkEvent(id: 'gone'));
    final r = await repo.softDelete('gone');
    expect(r.isOk, isTrue);
    final list = await repo.watchRecent().first;
    expect(list.where((x) => x.id == 'gone'), isEmpty);
  });

  test('updateAck 不允许 PENDING', () async {
    await repo.record(mkEvent(id: 'e1'));
    final r = await repo.updateAck(
      id: 'e1',
      ackStatus: AckStatus.pending,
    );
    expect(r.isErr, isTrue);
  });

  test('updateAck 拒绝 NOT_APPLICABLE 事件', () async {
    await repo.record(mkEvent(id: 'sys', req: AckRequirement.notApplicable));
    final r = await repo.updateAck(
      id: 'sys',
      ackStatus: AckStatus.confirmed,
    );
    expect(r.isErr, isTrue);
    // 断言后仍为 PENDING（未被写入）
    final list = await repo.watchRecent().first;
    final found = list.firstWhere((x) => x.id == 'sys');
    expect(found.ackStatus, AckStatus.pending);
    expect(found.ackAt, isNull);
  });

  test('updateAck 对不存在的事件返回 NotFound', () async {
    final r = await repo.updateAck(
      id: 'nope',
      ackStatus: AckStatus.confirmed,
    );
    expect(r.isErr, isTrue);
  });

  test('AckEventUseCase.dismiss 写入 DISMISSED', () async {
    await repo.record(mkEvent(id: 'e-dis'));
    final useCase = AckEventUseCase(repo);
    final r = await useCase.dismiss('e-dis', note: '误报');
    expect(r.isOk, isTrue);
    final list = await repo.watchRecent().first;
    final found = list.firstWhere((x) => x.id == 'e-dis');
    expect(found.ackStatus, AckStatus.dismissed);
    expect(found.ackAt, isNotNull);
    expect(found.ackNote, '误报');
  });

  test('已 CONFIRMED 的事件不可再改为 DISMISSED', () async {
    await repo.record(mkEvent(id: 'e-final', ack: AckStatus.confirmed));
    final useCase = AckEventUseCase(repo);
    final r = await useCase.dismiss('e-final', note: 'second thought');
    expect(r.isErr, isTrue);

    final list = await repo.watchRecent().first;
    final found = list.firstWhere((x) => x.id == 'e-final');
    expect(found.ackStatus, AckStatus.confirmed);
    expect(found.ackNote, isNull);
  });

  test('已 DISMISSED 的事件不可再改为 CONFIRMED', () async {
    await repo.record(mkEvent(id: 'e-final-2', ack: AckStatus.dismissed));
    final useCase = AckEventUseCase(repo);
    final r = await useCase.confirm('e-final-2', note: 'undo');
    expect(r.isErr, isTrue);

    final list = await repo.watchRecent().first;
    final found = list.firstWhere((x) => x.id == 'e-final-2');
    expect(found.ackStatus, AckStatus.dismissed);
    expect(found.ackNote, isNull);
  });

  test('softDelete 事件从 watchPendingAck 中隐藏', () async {
    await repo.record(mkEvent(id: 'pa'));
    var list = await repo.watchPendingAck().first;
    expect(list.map((e) => e.id), contains('pa'));
    await repo.softDelete('pa');
    list = await repo.watchPendingAck().first;
    expect(list.where((e) => e.id == 'pa'), isEmpty);
  });
}
