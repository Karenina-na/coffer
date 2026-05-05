import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/dashboard_providers.dart';

const List<String> kSupportedBaseCurrencies = [
  'CNY',
  'USD',
  'HKD',
  'EUR',
  'JPY',
  'SGD',
  'GBP',
];

/// 顶部「本位币」选择器。
///
/// 读写 [dashboardBaseCurrencyProvider]；用户在任一页面均可直接切换，
/// 不必再回到仪表盘英雄卡长按。
class BaseCurrencySwitcher extends ConsumerWidget {
  const BaseCurrencySwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dashboardBaseCurrencyProvider);
    final cs = Theme.of(context).colorScheme;
    // 小屏下省掉 language 图标与内外边距，只保留「币种码 + 下拉」
    final compact = MediaQuery.sizeOf(context).width < 380;
    return PopupMenuButton<String>(
      tooltip: '切换本位币',
      initialValue: current,
      onSelected: (code) =>
          ref.read(dashboardBaseCurrencyProvider.notifier).set(code),
      itemBuilder: (_) => [
        for (final c in kSupportedBaseCurrencies)
          PopupMenuItem<String>(
            value: c,
            child: Row(
              children: [
                Icon(
                  c == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: c == current ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(c),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(Icons.language, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              current,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
