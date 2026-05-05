// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AssetsTable get assets => attachedDatabase.assets;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
}
