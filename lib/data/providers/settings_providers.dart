import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/api_diagnostics_repository.dart';
import '../repositories/http_api_diagnostics_repository.dart';

final apiDiagnosticsRepositoryProvider = Provider<ApiDiagnosticsRepository>((ref) {
  final repo = HttpApiDiagnosticsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
