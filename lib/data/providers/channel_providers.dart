import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/account_channel_dao.dart';
import '../db/daos/channel_dao.dart';
import '../repositories/drift_account_channel_repository.dart';
import '../repositories/drift_channel_repository.dart';
import '../../domain/repositories/account_channel_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import 'account_providers.dart';

final channelDaoProvider = Provider<ChannelDao>((ref) {
  return ref.watch(appDatabaseProvider).channelDao;
});

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return DriftChannelRepository(ref.watch(channelDaoProvider));
});

final accountChannelDaoProvider = Provider<AccountChannelDao>((ref) {
  return ref.watch(appDatabaseProvider).accountChannelDao;
});

final accountChannelRepositoryProvider =
    Provider<AccountChannelRepository>((ref) {
  return DriftAccountChannelRepository(ref.watch(accountChannelDaoProvider));
});
