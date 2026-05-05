import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/errors.dart';

/// 把 HTTP 层异常统一映射到 [NetworkError]，供 UI / UseCase 判断是否重试。
AppError classifyNetworkException(String providerName, Object e) {
  if (e is TimeoutException) {
    return NetworkError(
      '$providerName timeout: $e',
      kind: NetworkErrorKind.timeout,
    );
  }
  if (e is SocketException || e is HttpException) {
    return NetworkError(
      '$providerName connectivity: $e',
      kind: NetworkErrorKind.connectivity,
    );
  }
  if (e is FormatException) {
    return NetworkError(
      '$providerName malformed: $e',
      kind: NetworkErrorKind.malformedResponse,
    );
  }
  return NetworkError(
    '$providerName unknown: $e',
    kind: NetworkErrorKind.unknown,
  );
}

/// 取响应体的短摘要，防止把包含 SQL / 堆栈 / token 的完整 body 暴露给 UI。
/// - 仅保留单行、最多 120 字符
/// - 完整 body 交由调用方自行 debugPrint
String _bodyPreview(String body) {
  if (body.isEmpty) return '';
  final oneLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  const maxLen = 120;
  if (oneLine.length <= maxLen) return oneLine;
  return '${oneLine.substring(0, maxLen)}…';
}

/// 把非 2xx 的 HTTP 响应映射到 [NetworkError]。
///
/// 仅在 debug 下记录脱敏后的短摘要；错误消息里也只保留短摘要，
/// 避免服务端调试信息沿错误链传到 UI / 日志系统。
AppError classifyHttpStatus(String providerName, int status, String body) {
  final preview = _bodyPreview(body);
  if (kDebugMode && preview.isNotEmpty) {
    debugPrint('[$providerName] http $status body: $preview');
  }
  final suffix = preview.isEmpty ? '' : ': $preview';
  if (status == 429) {
    return NetworkError(
      '$providerName rate limited (429)',
      kind: NetworkErrorKind.rateLimited,
      statusCode: status,
    );
  }
  if (status >= 500) {
    return NetworkError(
      '$providerName http $status$suffix',
      kind: NetworkErrorKind.serverError,
      statusCode: status,
    );
  }
  if (status >= 400) {
    return NetworkError(
      '$providerName http $status$suffix',
      kind: NetworkErrorKind.clientError,
      statusCode: status,
    );
  }
  return NetworkError(
    '$providerName http $status',
    kind: NetworkErrorKind.unknown,
    statusCode: status,
  );
}
