import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/account_channels.dart';

part 'account_channel_dao.g.dart';

@DriftAccessor(tables: [AccountChannels])
class AccountChannelDao extends DatabaseAccessor<AppDatabase>
    with _$AccountChannelDaoMixin {
  AccountChannelDao(super.db);

  Stream<List<AccountChannelRow>> watchAll() {
    return select(accountChannels).watch();
  }

  Stream<List<AccountChannelRow>> watchByAccount(String accountId) {
    return (select(accountChannels)
          ..where((t) => t.accountId.equals(accountId)))
        .watch();
  }

  Future<List<AccountChannelRow>> listByChannel(String channelId) {
    return (select(accountChannels)
          ..where((t) => t.channelId.equals(channelId)))
        .get();
  }

  Future<void> upsert(AccountChannelsCompanion row) async {
    await into(accountChannels).insertOnConflictUpdate(row);
  }

  Future<int> removeLink({
    required String accountId,
    required String channelId,
  }) {
    return (delete(accountChannels)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.channelId.equals(channelId)))
        .go();
  }

  Future<int> deleteAllForAccount(String accountId) {
    return (delete(accountChannels)..where((t) => t.accountId.equals(accountId)))
        .go();
  }

  Future<int> deleteAllForChannel(String channelId) {
    return (delete(accountChannels)..where((t) => t.channelId.equals(channelId)))
        .go();
  }
}
