// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_channel_dao.dart';

// ignore_for_file: type=lint
mixin _$AccountChannelDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $ChannelsTable get channels => attachedDatabase.channels;
  $AccountChannelsTable get accountChannels => attachedDatabase.accountChannels;
  AccountChannelDaoManager get managers => AccountChannelDaoManager(this);
}

class AccountChannelDaoManager {
  final _$AccountChannelDaoMixin _db;
  AccountChannelDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$AccountChannelsTableTableManager get accountChannels =>
      $$AccountChannelsTableTableManager(
        _db.attachedDatabase,
        _db.accountChannels,
      );
}
