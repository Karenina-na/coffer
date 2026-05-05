/// 文本匹配打分工具。
///
/// 规则（分值越高越靠前）：
/// - 完全等于：100
/// - 前缀匹配：80
/// - 词首匹配（空格 / - / _ / : / / 后）：60
/// - 子串匹配：40
/// - 不匹配：0
///
/// 多字段择优（max），便于把"标签"字段和"副标题"字段分别算分。
library;

const int _kScoreExact = 100;
const int _kScorePrefix = 80;
const int _kScoreWordBoundary = 60;
const int _kScoreContains = 40;

int scoreText(String haystack, String lowercaseQuery) {
  if (haystack.isEmpty || lowercaseQuery.isEmpty) return 0;
  final h = haystack.toLowerCase();
  if (h == lowercaseQuery) return _kScoreExact;
  if (h.startsWith(lowercaseQuery)) return _kScorePrefix;
  final idx = h.indexOf(lowercaseQuery);
  if (idx < 0) return 0;
  // 词首：前一位是分隔符
  const sep = {' ', '-', '_', ':', '/', '.', '·'};
  if (idx > 0 && sep.contains(h[idx - 1])) return _kScoreWordBoundary;
  return _kScoreContains;
}

int scoreMax(Iterable<String?> fields, String lowercaseQuery) {
  int best = 0;
  for (final f in fields) {
    if (f == null || f.isEmpty) continue;
    final s = scoreText(f, lowercaseQuery);
    if (s > best) best = s;
    if (best == 100) break;
  }
  return best;
}
