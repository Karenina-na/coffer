import 'dart:async';

import 'package:http/http.dart' as http;

import '../../domain/repositories/api_diagnostics_repository.dart';

class HttpApiDiagnosticsRepository implements ApiDiagnosticsRepository {
  HttpApiDiagnosticsRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> dispose() async {
    _client.close();
  }

  @override
  Future<ApiDiagnosticResult> probe(ApiDiagnosticEndpoint endpoint) async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _client
          .get(
            endpoint.testUri,
            headers: const {'User-Agent': 'Coffer/1 (diag)'},
          )
          .timeout(const Duration(seconds: 10));
      sw.stop();
      final ok = resp.statusCode < 400;
      return ApiDiagnosticResult(
        ok: ok,
        statusCode: resp.statusCode,
        errorMessage: ok ? null : 'HTTP ${resp.statusCode}',
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return ApiDiagnosticResult(
        ok: false,
        statusCode: null,
        errorMessage: _shortError(e),
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  String _shortError(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) return '超时';
    if (s.contains('SocketException')) return '无法连接';
    if (s.contains('HandshakeException')) return 'TLS 握手失败';
    if (s.length > 40) return '${s.substring(0, 40)}…';
    return s;
  }
}
