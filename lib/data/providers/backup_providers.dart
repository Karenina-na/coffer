import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/db_snapshot_repository.dart';
import '../backup/db_snapshot.dart';
import 'account_providers.dart';

final dbSnapshotRepositoryProvider = Provider<DbSnapshotRepository>((ref) {
  return DbSnapshotService(ref.watch(appDatabaseProvider));
});
