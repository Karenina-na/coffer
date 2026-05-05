import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_event_repository.dart';
import 'package:gwp/domain/entities/domain_event.dart';
import 'package:gwp/domain/entities/event_enums.dart';

void main() {
  late AppDatabase db;
  late DriftEventRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftEventRepository(db.eventDao);
  });

  tearDown(() => db.close());

  DomainEvent mk({required String id, String? sk}) {
    final now = DateTime.utc(2025, 1, 1, 12);
    return DomainEvent(
      id: id,
      eventType: 'DUP_TEST',
      relatedModel: RelatedModel.account,
      relatedId: 'acc-1',
      triggerTime: now,
      status: EventStatus.triggered,
      ackRequirement: AckRequirement.notApplicable,
      ackStatus: AckStatus.pending,
      sourceKey: sk,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Event 幂等写入（upsertBySourceKey）', () {
    test('相同 sourceKey 二次 record 返回首条行，不产生重复', () async {
      final first = await repo.record(mk(id: 'e1', sk: 'DUP:1'));
      final second = await repo.record(mk(id: 'e2', sk: 'DUP:1'));

      expect(first.isOk, true);
      expect(second.isOk, true);
      // 返回的都是首条（id=e1）
      expect(second.valueOrNull!.id, 'e1');

      final all = await (db.select(db.events)).get();
      expect(all.length, 1);
      expect(all.first.id, 'e1');
    });

    test('sourceKey=null 时不去重，两次写入产生两行', () async {
      await repo.record(mk(id: 'n1', sk: null));
      await repo.record(mk(id: 'n2', sk: null));

      final all = await (db.select(db.events)).get();
      expect(all.length, 2);
    });

    test('sourceKey 为空字符串等价于 null（不去重）', () async {
      await repo.record(mk(id: 'x1', sk: ''));
      await repo.record(mk(id: 'x2', sk: ''));

      final all = await (db.select(db.events)).get();
      expect(all.length, 2);
    });
  });
}
