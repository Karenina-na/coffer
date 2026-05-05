// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_price_history_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetPriceHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetPriceHistoryTable get assetPriceHistory =>
      attachedDatabase.assetPriceHistory;
  AssetPriceHistoryDaoManager get managers => AssetPriceHistoryDaoManager(this);
}

class AssetPriceHistoryDaoManager {
  final _$AssetPriceHistoryDaoMixin _db;
  AssetPriceHistoryDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetPriceHistoryTableTableManager get assetPriceHistory =>
      $$AssetPriceHistoryTableTableManager(
        _db.attachedDatabase,
        _db.assetPriceHistory,
      );
}
