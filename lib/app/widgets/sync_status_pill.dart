import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/valuation/asset_valuator.dart';
import '../../features/sync/presentation/sync_providers.dart';

/// 顶部「同步状态」药丸。
///
/// - 主体（图标 + 文案）：点击触发默认全量刷新（行情 + 汇率）
/// - 尾部 `▾` 展开模式菜单：只刷汇率 / 只刷行情 / 全量 vs 增量
///
/// 状态三态：空闲（展示相对时间）/ 同步中（spinner）/ 失败（红色 + tooltip 错误）。
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final cs = Theme.of(context).colorScheme;

    late IconData icon;
    late Color color;
    late String tooltip;

    if (sync.isSyncing) {
      icon = Icons.sync;
      color = cs.primary;
      tooltip = '正在拉取行情与汇率';
    } else if (sync.lastError != null) {
      icon = Icons.sync_problem;
      color = cs.error;
      tooltip = '同步失败：${sync.lastError}';
    } else if (sync.lastSyncAt == null) {
      icon = Icons.cloud_off_outlined;
      color = cs.onSurfaceVariant;
      tooltip = '未同步 · 点击拉取最新行情与汇率';
    } else {
      icon = Icons.cloud_done_outlined;
      color = cs.primary;
      tooltip =
          '上次同步：${_formatRelative(sync.lastSyncAt!)}（${_formatAbsolute(sync.lastSyncAt!)}）';
    }

    void run({required SyncScope scope, SyncMode mode = SyncMode.full}) {
      ref.read(globalRefreshProvider).run(scope: scope, rateMode: mode);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: tooltip,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                onTap: sync.isSyncing ? null : () => run(scope: SyncScope.all),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                  child: sync.isSyncing
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      : Icon(icon, size: 16, color: color),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 16,
              color: color.withValues(alpha: 0.25),
            ),
            MenuAnchor(
              alignmentOffset: const Offset(0, 4),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.sync, size: 18),
                  onPressed: sync.isSyncing
                      ? null
                      : () => run(scope: SyncScope.all),
                  child: const Text('全量刷新（行情 + 汇率）'),
                ),
                const Divider(height: 8),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.trending_up_outlined, size: 18),
                  onPressed: sync.isSyncing
                      ? null
                      : () => run(
                          scope: SyncScope.ratesOnly,
                          mode: SyncMode.incremental,
                        ),
                  child: const Text('仅汇率 · 增量'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.timeline_outlined, size: 18),
                  onPressed: sync.isSyncing
                      ? null
                      : () => run(
                          scope: SyncScope.ratesOnly,
                          mode: SyncMode.full,
                        ),
                  child: const Text('仅汇率 · 全量（8 日序列）'),
                ),
                const Divider(height: 8),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.stacked_line_chart, size: 18),
                  onPressed: sync.isSyncing
                      ? null
                      : () => run(scope: SyncScope.assetsOnly),
                  child: const Text('仅资产行情'),
                ),
              ],
              builder: (context, controller, _) => InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
                  child: Icon(Icons.arrow_drop_down, size: 18, color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 30) return '刚刚';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  static String _formatAbsolute(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${ts.year}-${two(ts.month)}-${two(ts.day)} '
        '${two(ts.hour)}:${two(ts.minute)}';
  }
}
