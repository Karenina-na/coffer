import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/backup_providers.dart';
import '../../../domain/usecases/backup_restore.dart';

export '../../../data/providers/backup_providers.dart'
    show dbSnapshotRepositoryProvider;

final exportBackupUseCaseProvider = Provider<ExportBackupUseCase>((ref) {
  return ExportBackupUseCase(ref.watch(dbSnapshotRepositoryProvider));
});

final importBackupUseCaseProvider = Provider<ImportBackupUseCase>((ref) {
  return ImportBackupUseCase(ref.watch(dbSnapshotRepositoryProvider));
});
