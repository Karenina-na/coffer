class ApiDiagnosticEndpoint {
  const ApiDiagnosticEndpoint({
    required this.label,
    required this.host,
    required this.testUri,
    required this.description,
  });

  final String label;
  final String host;
  final Uri testUri;
  final String description;
}

class ApiDiagnosticResult {
  const ApiDiagnosticResult({
    required this.ok,
    required this.statusCode,
    this.errorMessage,
    required this.latencyMs,
  });

  final bool ok;
  final int? statusCode;
  final String? errorMessage;
  final int latencyMs;
}

abstract class ApiDiagnosticsRepository {
  Future<ApiDiagnosticResult> probe(ApiDiagnosticEndpoint endpoint);
}
