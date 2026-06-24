import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/channel_providers.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account_channel.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/usecases/link_account_channel.dart';
import '../../../domain/usecases/plan_transfer_route.dart';
import '../../../domain/usecases/save_account_channel_config.dart';
import '../../../domain/usecases/save_channel.dart';
import '../../../domain/usecases/set_channel_status.dart';
import '../../account/presentation/account_providers.dart';

export '../../../data/providers/channel_providers.dart'
    show channelRepositoryProvider, accountChannelRepositoryProvider;

final channelListProvider = StreamProvider<List<Channel>>((ref) {
  return ref.watch(channelRepositoryProvider).watchAll();
});

final accountChannelListProvider = StreamProvider<List<AccountChannel>>((ref) {
  return ref.watch(accountChannelRepositoryProvider).watchAll();
});

final accountChannelsByAccountProvider =
    StreamProvider.family<List<AccountChannel>, String>((ref, accountId) {
      return ref
          .watch(accountChannelRepositoryProvider)
          .watchByAccount(accountId);
    });

final planTransferRouteUseCaseProvider = Provider<PlanTransferRouteUseCase>((
  ref,
) {
  return PlanTransferRouteUseCase(
    ref.watch(accountRepositoryProvider),
    ref.watch(channelRepositoryProvider),
    ref.watch(accountChannelRepositoryProvider),
  );
});

final saveChannelUseCaseProvider = Provider<SaveChannelUseCase>((ref) {
  return SaveChannelUseCase(
    ref.watch(channelRepositoryProvider),
    ref.watch(dictRepositoryProvider),
  );
});

final setChannelStatusUseCaseProvider = Provider<SetChannelStatusUseCase>((
  ref,
) {
  return SetChannelStatusUseCase(ref.watch(channelRepositoryProvider));
});

final linkAccountChannelUseCaseProvider = Provider<LinkAccountChannelUseCase>((
  ref,
) {
  return LinkAccountChannelUseCase(
    ref.watch(accountChannelRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(channelRepositoryProvider),
  );
});

final saveAccountChannelConfigUseCaseProvider =
    Provider<SaveAccountChannelConfigUseCase>((ref) {
      return SaveAccountChannelConfigUseCase(
        ref.watch(accountChannelRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(channelRepositoryProvider),
        ref.watch(dictRepositoryProvider),
      );
    });
