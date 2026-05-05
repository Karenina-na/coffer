/// Domain 层通用日期工具。
///
/// - [zeroPad2]：整数补零为 2 位字符串，如 `7` → `'07'`。
///   用于构造日期键（`YYYYMMDD`）和 sourceKey。
/// - [utcDayKey]：将 [DateTime] 转换为 UTC 8 位日期字符串 `'YYYYMMDD'`，
///   用于 `sourceKey`、`dayKey` 等唯一键构造。
library;

/// 将整数 [n] 补零填充到 2 位，如 `7` → `'07'`，`15` → `'15'`。
String zeroPad2(int n) => n.toString().padLeft(2, '0');

/// 将 [dt] 转换为 UTC 格式的 8 位日期字符串 `'YYYYMMDD'`。
///
/// 所有 sourceKey 均基于 UTC 日期，避免跨时区时同一天产生不同键值。
String utcDayKey(DateTime dt) {
  final d = dt.toUtc();
  return '${d.year}${zeroPad2(d.month)}${zeroPad2(d.day)}';
}
