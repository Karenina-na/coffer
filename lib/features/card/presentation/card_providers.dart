import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/providers/card_providers.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/usecases/create_card.dart';
import '../../account/presentation/account_providers.dart';

export '../../../data/providers/card_providers.dart'
    show cryptoServiceProvider, cardDaoProvider, cardRepositoryProvider;

final cardListProvider = StreamProvider<List<BankCard>>((ref) {
  return ref.watch(cardRepositoryProvider).watchAll();
});

final createCardUseCaseProvider = Provider<CreateCardUseCase>((ref) {
  const uuid = Uuid();
  return CreateCardUseCase(
    ref.watch(cardRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    idGenerator: uuid.v4,
    now: DateTime.now,
  );
});
