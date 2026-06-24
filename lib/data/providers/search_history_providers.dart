import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/daos/search_history_dao.dart';
import '../repositories/drift_search_history_repository.dart';
import '../../domain/repositories/search_history_repository.dart';
import 'account_providers.dart';

final searchHistoryDaoProvider = Provider<SearchHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).searchHistoryDao;
});

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return DriftSearchHistoryRepository(ref.watch(searchHistoryDaoProvider));
});
