import '../errors.dart';

/// 把 [AppError] 或任意异常对象映射为面向用户的中文提示。
///
/// 设计原则：
/// - 短句、动词明确（"网络不稳定"、"数据未找到"等），不暴露堆栈 / 类名
/// - 瞬时网络错误（timeout/connectivity/serverError）统一提示可重试
/// - 4xx / 输入不合法 → 提示检查输入
/// - 其他（Storage/Crypto/Unknown）→ 保留原始 message 做诊断，前缀中文分类
///
/// 这是 UI 层唯一允许的 `err -> string` 入口，所有 SnackBar/对话框错误文案
/// 都应经此函数。
String errorToMessage(Object? error) {
  if (error == null) return '未知错误';
  if (error is! AppError) {
    // 非 AppError（通常是上层未捕获的 Exception / StateError 等），
    // 不直接 toString 避免泄露类名。
    return '操作失败：$error';
  }
  return switch (error) {
    NetworkError(:final kind, :final statusCode, :final message) =>
      _networkMessage(kind, statusCode, message),
    NotFoundError() => '未找到相关数据',
    ValidationError(:final message) => '输入有误：$message',
    StorageError(:final message) => '本地存储失败：$message',
    CryptoError() => '加解密失败，请重启后重试',
    UnknownError(:final message) => '操作失败：$message',
  };
}

String _networkMessage(NetworkErrorKind kind, int? status, String raw) {
  return switch (kind) {
    NetworkErrorKind.timeout => '网络请求超时，请检查网络后重试',
    NetworkErrorKind.connectivity => '网络不可用，请检查连接',
    NetworkErrorKind.serverError => '服务器暂不可用 (${status ?? 5}xx)，稍后重试',
    NetworkErrorKind.rateLimited => '请求过于频繁，请稍后再试',
    NetworkErrorKind.clientError => '请求被拒绝 (HTTP ${status ?? ''})：$raw',
    NetworkErrorKind.malformedResponse => '服务器返回数据异常，请稍后重试',
    NetworkErrorKind.unknown => '网络异常：$raw',
  };
}
