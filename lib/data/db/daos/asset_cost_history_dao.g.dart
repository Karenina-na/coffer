// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_cost_history_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetCostHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetCostHistoryTable get assetCostHistory =>
      attachedDatabase.assetCostHistory;
  AssetCostHistoryDaoManager get managers => AssetCostHistoryDaoManager(this);
}

class AssetCostHistoryDaoManager {
  final _$AssetCostHistoryDaoMixin _db;
  AssetCostHistoryDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetCostHistoryTableTableManager get assetCostHistory =>
      $$AssetCostHistoryTableTableManager(
        _db.attachedDatabase,
        _db.assetCostHistory,
      );
}
