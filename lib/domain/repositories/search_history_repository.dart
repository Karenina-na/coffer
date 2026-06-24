class SearchHistoryVisitRecord {
  const SearchHistoryVisitRecord({
    required this.feature,
    required this.targetId,
    required this.label,
    this.sublabel,
    required this.visitedAt,
  });

  final String feature;
  final String targetId;
  final String label;
  final String? sublabel;
  final DateTime visitedAt;
}

abstract interface class SearchHistoryRepository {
  Future<void> migrateLegacyHistoryIfNeeded();

  Future<List<String>> listQueries({int limit});

  Future<List<SearchHistoryVisitRecord>> listVisits({int limit});

  Future<void> upsertQuery({
    required String query,
    required String normalized,
    required DateTime now,
  });

  Future<void> upsertVisit({
    required String feature,
    required String targetId,
    required String label,
    String? sublabel,
    required DateTime visitedAt,
  });

  Future<void> clearQueries();
}
