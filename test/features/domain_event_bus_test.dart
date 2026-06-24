import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/domain/entities/domain_event.dart';
import 'package:coffer/domain/entities/event_enums.dart';
import 'package:coffer/domain/events/event_bus.dart';

DomainEvent _evt({
  String id = 'e1',
  String type = 'TEST',
  RelatedModel model = RelatedModel.asset,
  String relatedId = 'a1',
}) {
  final now = DateTime.utc(2025, 1, 1);
  return DomainEvent(
    id: id,
    eventType: type,
    relatedModel: model,
    relatedId: relatedId,
    triggerTime: now,
    status: EventStatus.triggered,
    ackRequirement: AckRequirement.notApplicable,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late DomainEventBus bus;

  setUp(() {
    bus = DomainEventBus();
  });

  tearDown(() async {
    await bus.dispose();
  });

  test('emit broadcasts on all stream', () async {
    final events = <DomainEvent>[];
    bus.all.listen(events.add);

    final e = _evt();
    bus.emit(e);
    await Future<void>.delayed(Duration.zero);

    expect(events, [e]);
  });

  test('ofType filters by eventType', () async {
    final received = <DomainEvent>[];
    bus.ofType('MATCH').listen(received.add);

    bus.emit(_evt(id: 'e1', type: 'MATCH'));
    bus.emit(_evt(id: 'e2', type: 'OTHER'));
    await Future<void>.delayed(Duration.zero);

    expect(received.length, 1);
    expect(received.single.id, 'e1');
  });

  test('forRelated filters by model + id', () async {
    final received = <DomainEvent>[];
    bus.forRelated(RelatedModel.asset, 'a1').listen(received.add);

    bus.emit(_evt(id: 'e1', model: RelatedModel.asset, relatedId: 'a1'));
    bus.emit(_evt(id: 'e2', model: RelatedModel.asset, relatedId: 'a2'));
    bus.emit(_evt(id: 'e3', model: RelatedModel.account, relatedId: 'a1'));
    await Future<void>.delayed(Duration.zero);

    expect(received.length, 1);
    expect(received.single.id, 'e1');
  });

  test('multiple subscribers all receive event', () async {
    final a = <DomainEvent>[];
    final b = <DomainEvent>[];
    bus.all.listen(a.add);
    bus.all.listen(b.add);

    bus.emit(_evt());
    await Future<void>.delayed(Duration.zero);

    expect(a.length, 1);
    expect(b.length, 1);
  });

  test('dispose: emit after dispose does not throw', () async {
    await bus.dispose();
    expect(() => bus.emit(_evt()), returnsNormally);
  });

  test('dispose: stream completes', () async {
    final done = Completer<void>();
    bus.all.listen((_) {}, onDone: done.complete);
    await bus.dispose();
    expect(done.isCompleted, isTrue);
  });
}
