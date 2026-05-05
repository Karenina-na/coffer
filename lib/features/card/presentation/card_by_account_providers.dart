import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/card.dart';
import '../../../domain/usecases/aggregate_account_value.dart';
import '../../exchange_rate/presentation/exchange_rate_providers.dart';
import 'card_providers.dart';

final cardsByAccountProvider =
    StreamProvider.family<List<BankCard>, String>((ref, accountId) {
  return ref.watch(cardRepositoryProvider).watchByAccount(accountId);
});

final aggregateAccountValueUseCaseProvider =
    Provider<AggregateAccountValueUseCase>((ref) {
  return AggregateAccountValueUseCase(ref.watch(priceProviderProvider));
});
