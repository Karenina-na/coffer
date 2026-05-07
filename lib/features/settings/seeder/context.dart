import 'models.dart';

class SeedAssemblyContext {
  SeedAssemblyContext({required this.deps, required this.now});

  final SeedDeps deps;
  final DateTime now;
  final List<String> errors = <String>[];
  final Map<String, String> accountIds = <String, String>{};
  final Map<String, String> assetIds = <String, String>{};
  final Map<String, String> channelIds = <String, String>{};
  final Map<String, String> cardIds = <String, String>{};

  Future<void> collect<T>(
    Future<dynamic> future,
    void Function(T value) onOk,
    String label,
  ) async {
    final result = await future;
    result.when(
      ok: (value) => onOk(value as T),
      err: (e) => errors.add('$label: ${e.message}'),
    );
  }
}
