/// Domain-level error taxonomy. Infrastructure layers should translate
/// platform exceptions into these before crossing layer boundaries.
sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class ValidationError extends AppError {
  const ValidationError(super.message);
}

final class StorageError extends AppError {
  const StorageError(super.message);
}

final class CryptoError extends AppError {
  const CryptoError(super.message);
}

/// 网络错误分类。`kind` 用于 UI 侧决策：哪些可重试、哪些提示用户检查网络、
/// 哪些直接放弃（4xx）。所有 Provider 向上抛出前必须映射到具体 kind。
final class NetworkError extends AppError {
  const NetworkError(super.message, {required this.kind, this.statusCode});

  final NetworkErrorKind kind;
  final int? statusCode;

  /// 是否是值得自动重试的瞬时错误。
  bool get isTransient => switch (kind) {
    NetworkErrorKind.timeout => true,
    NetworkErrorKind.connectivity => true,
    NetworkErrorKind.serverError => true,
    NetworkErrorKind.rateLimited => true,
    NetworkErrorKind.clientError => false,
    NetworkErrorKind.malformedResponse => false,
    NetworkErrorKind.unknown => false,
  };
}

enum NetworkErrorKind {
  /// `TimeoutException` / `http` 请求超时。
  timeout,

  /// SocketException / HttpException / ClientException（DNS、握手、拒绝等）。
  connectivity,

  /// HTTP 5xx。
  serverError,

  /// HTTP 429（独立分类以便实施 exponential backoff）。
  rateLimited,

  /// HTTP 4xx（非 429）。通常是请求本身不合法，不应重试。
  clientError,

  /// 响应为 200 但无法解析或缺关键字段。
  malformedResponse,

  /// 其它未分类异常。
  unknown,
}

final class UnknownError extends AppError {
  const UnknownError(super.message);
}
