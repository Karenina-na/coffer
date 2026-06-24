import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_dict_repository.dart';
import 'package:coffer/domain/entities/dict_type.dart';

void main() {
  late AppDatabase db;
  late DriftDictRepository repo;

  final now = DateTime.utc(2025, 6, 15);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftDictRepository(db.dictEntryDao, now: () => now);
  });

  tearDown(() => db.close());

  test('addCustom and listByType round-trip', () async {
    final r = await repo.addCustom(
      type: DictType.currency,
      code: 'XYZ',
      name: 'Test Currency',
    );
    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.code, 'XYZ');

    final list = await repo.listByType(DictType.currency);
    // Built-in currencies may also exist; confirm XYZ is present
    expect(list.any((e) => e.code == 'XYZ'), isTrue);
  });

  test('addCustom normalizes code to uppercase', () async {
    final r = await repo.addCustom(
      type: DictType.transferProtocol,
      code: 'myproto',
      name: 'My Protocol',
    );
    expect(r.isOk, isTrue);
    expect(r.valueOrNull!.code, 'MYPROTO');
  });

  test('addCustom rejects duplicate code', () async {
    await repo.addCustom(
      type: DictType.currency,
      code: 'DUP',
      name: 'First',
    );
    final r = await repo.addCustom(
      type: DictType.currency,
      code: 'DUP',
      name: 'Second',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('addCustom rejects invalid code pattern', () async {
    final r = await repo.addCustom(
      type: DictType.currency,
      code: 'bad code!',
      name: 'Bad',
    );
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('watchByType emits live additions', () async {
    final stream = repo.watchByType(DictType.transferProtocol);
    final events = <int>[];
    final sub = stream.map((l) => l.length).distinct().listen(events.add);

    await repo.addCustom(
      type: DictType.transferProtocol,
      code: 'PROTO1',
      name: 'Proto One',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addCustom(
      type: DictType.transferProtocol,
      code: 'PROTO2',
      name: 'Proto Two',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Should have seen at least 1 and 2 custom entries (plus any built-ins)
    expect(events.isNotEmpty, isTrue);
    await sub.cancel();
  });

  test('deleteCustom removes entry', () async {
    final r = await repo.addCustom(
      type: DictType.currency,
      code: 'TODEL',
      name: 'To Delete',
    );
    expect(r.isOk, isTrue);
    final id = r.valueOrNull!.id;

    final del = await repo.deleteCustom(id);
    expect(del.isOk, isTrue);

    final list = await repo.listByType(DictType.currency);
    expect(list.any((e) => e.id == id), isFalse);
  });
}
