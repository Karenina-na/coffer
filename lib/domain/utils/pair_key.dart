/// 货币对 key 约定：`BASE/QUOTE`，如 `USD/CNY`。
///
/// 基础工具，domain / data / presentation 通用，避免分层导入违规。
String pairKeyOf(String base, String quote) =>
    '${base.toUpperCase()}/${quote.toUpperCase()}';
