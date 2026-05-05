import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/channel_providers.dart';
import '../../../domain/entities/account_channel.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/usecases/plan_transfer_route.dart';
import '../../account/presentation/account_providers.dart';

export '../../../data/providers/channel_providers.dart'
    show
        channelDaoProvider,
        channelRepositoryProvider,
        accountChannelDaoProvider,
        accountChannelRepositoryProvider;

final channelListProvider = StreamProvider<List<Channel>>((ref) {
  return ref.watch(channelRepositoryProvider).watchAll();
});

final accountChannelListProvider =
    StreamProvider<List<AccountChannel>>((ref) {
  return ref.watch(accountChannelRepositoryProvider).watchAll();
});

final accountChannelsByAccountProvider =
    StreamProvider.family<List<AccountChannel>, String>((ref, accountId) {
  return ref
      .watch(accountChannelRepositoryProvider)
      .watchByAccount(accountId);
});

final planTransferRouteUseCaseProvider =
    Provider<PlanTransferRouteUseCase>((ref) {
  return PlanTransferRouteUseCase(
    ref.watch(accountRepositoryProvider),
    ref.watch(channelRepositoryProvider),
    ref.watch(accountChannelRepositoryProvider),
  );
});
