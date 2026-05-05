import 'package:flutter/material.dart';

/// 在 [text] 中高亮所有匹配 [query] 的子串（大小写不敏感）。
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final hl = (highlightStyle ??
            TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ))
        .merge(base.copyWith(fontWeight: FontWeight.w700));

    if (query.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: overflow);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final idx = lower.indexOf(q, i);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(i), style: base));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: text.substring(i, idx), style: base));
      }
      spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: hl));
      i = idx + q.length;
    }

    return RichText(
      text: TextSpan(children: spans, style: base),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
