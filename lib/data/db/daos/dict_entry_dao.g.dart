// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dict_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$DictEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $DictEntriesTable get dictEntries => attachedDatabase.dictEntries;
  DictEntryDaoManager get managers => DictEntryDaoManager(this);
}

class DictEntryDaoManager {
  final _$DictEntryDaoMixin _db;
  DictEntryDaoManager(this._db);
  $$DictEntriesTableTableManager get dictEntries =>
      $$DictEntriesTableTableManager(_db.attachedDatabase, _db.dictEntries);
}
