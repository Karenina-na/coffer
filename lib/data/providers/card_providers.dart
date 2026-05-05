import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto_service.dart';
import '../db/daos/card_dao.dart';
import '../repositories/drift_card_repository.dart';
import '../../domain/repositories/card_repository.dart';
import 'account_providers.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

final cardDaoProvider = Provider<CardDao>((ref) {
  return ref.watch(appDatabaseProvider).cardDao;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return DriftCardRepository(
    ref.watch(cardDaoProvider),
    ref.watch(cryptoServiceProvider),
  );
});
