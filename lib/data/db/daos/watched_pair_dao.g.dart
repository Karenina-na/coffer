// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watched_pair_dao.dart';

// ignore_for_file: type=lint
mixin _$WatchedPairDaoMixin on DatabaseAccessor<AppDatabase> {
  $WatchedPairsTable get watchedPairs => attachedDatabase.watchedPairs;
  WatchedPairDaoManager get managers => WatchedPairDaoManager(this);
}

class WatchedPairDaoManager {
  final _$WatchedPairDaoMixin _db;
  WatchedPairDaoManager(this._db);
  $$WatchedPairsTableTableManager get watchedPairs =>
      $$WatchedPairsTableTableManager(_db.attachedDatabase, _db.watchedPairs);
}
