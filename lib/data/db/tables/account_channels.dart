import 'package:drift/drift.dart';

import 'accounts.dart';
import 'channels.dart';

/// AccountChannel: 账户与通道的多对多关联。
///
/// See doc/data-definitions.md §4.1.
@DataClassName('AccountChannelRow')
class AccountChannels extends Table {
  TextColumn get accountId =>
      text().named('account_id').references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get channelId =>
      text().named('channel_id').references(Channels, #id, onDelete: KeyAction.cascade)();
  TextColumn get feeRateOverride => text().named('fee_rate_override').nullable()();
  TextColumn get fixedFeeOverride => text().named('fixed_fee_override').nullable()();
  TextColumn get feeCurrencyOverride =>
      text().named('fee_currency_override').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {accountId, channelId};
}
