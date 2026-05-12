import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/builtin_badge.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../core/ui/protocol_display.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../../../domain/entities/dict_entry.dart';
import '../../../domain/entities/dict_type.dart';
import 'channel_providers.dart';

String _channelRegionSuffix(Channel channel, RegionIndex regionIndex) {
  final allowed = (channel.sovereigntyRegionRule?['allowedRegions'] as List?)
      ?.whereType<String>()
      .toList(growable: false);
  if (allowed == null || allowed.length != 1) return '';
  return ' · ${regionLabel(regionIndex, allowed.single)}';
}

class ChannelListPage extends ConsumerStatefulWidget {
  const ChannelListPage({super.key});

  @override
  ConsumerState<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends ConsumerState<ChannelListPage> {
  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelListProvider);
    final regionIndexAsync = ref.watch(regionMetaIndexProvider);
    final protocolEntriesAsync = ref.watch(dictEntriesProvider(DictType.transferProtocol));
    return Scaffold(
      appBar: const AppTopBar(title: Text('转账通道')),
      body: channels.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(channelListProvider),
        ),
        data: (list) {
          final regionIndex = regionIndexAsync.value ?? const <String, RegionMeta>{};
          final ProtocolIndex protocolIndex = {
            for (final entry in protocolEntriesAsync.value ?? const <DictEntry>[]) entry.code: entry,
          };
          if (list.isEmpty) {
            return const GwpEmptyState(
              icon: Icons.swap_horiz_outlined,
              title: '还没有通道',
              subtitle: '从右上「更多 → 新建」添加转账通道策略',
            );
          }
          final enabled = list.where((c) => c.status == ChannelStatus.enabled).length;
          final protocols = list.map((c) => c.transferProtocol).toSet().length;
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(
              left: GwpSpacing.base,
              right: GwpSpacing.base,
              top: GwpSpacing.md,
              bottom: 16,
            ),
            buildDefaultDragHandles: false,
            header: Column(
              children: [
                _SummaryHeader(
                  total: list.length,
                  enabled: enabled,
                  protocols: protocols,
                ),
                const SizedBox(height: GwpSpacing.md),
              ],
            ),
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final reordered = [...list];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final result = await ref
                  .read(channelRepositoryProvider)
                  .reorder(reordered.map((e) => e.id).toList(growable: false));
              if (result.isErr && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('重排失败：${result.errorOrNull?.message ?? '未知错误'}'),
                  ),
                );
              }
            },
            itemBuilder: (_, i) => Padding(
              key: ValueKey('channel-${list[i].id}'),
              padding: EdgeInsets.only(bottom: i < list.length - 1 ? GwpSpacing.sm : 0),
              child: _ChannelCard(
                channel: list[i],
                regionIndex: regionIndex,
                protocolIndex: protocolIndex,
                reorderIndex: i,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Summary header
// ──────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.total,
    required this.enabled,
    required this.protocols,
  });

  final int total;
  final int enabled;
  final int protocols;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.base),
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _KpiCell(label: '总通道', value: '$total', color: GwpColors.textPrimary),
          _divider(),
          _KpiCell(label: '已启用', value: '$enabled', color: GwpColors.positive),
          _divider(),
          _KpiCell(label: '协议数', value: '$protocols', color: GwpColors.info),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 0.5,
        height: 28,
        color: GwpColors.border,
        margin: const EdgeInsets.symmetric(horizontal: GwpSpacing.sm),
      );
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: GwpTypo.monoFont,
              fontFeatures: GwpTypo.tabularFigures,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: GwpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Channel card
// ──────────────────────────────────────────────────────────────

const _protocolColors = <String, Color>{
  'SWIFT': Color(0xFF64748B),
  'ACH': Color(0xFF22C55E),
  'SEPA': Color(0xFF8B5CF6),
  'CNAPS': Color(0xFFEF4444),
  'FPS': Color(0xFFEC4899),
  'CHATS': Color(0xFFF59E0B),
};

const _protocolIcons = <String, IconData>{
  'SWIFT': Icons.language_outlined,
  'ACH': Icons.account_balance_outlined,
  'SEPA': Icons.euro_outlined,
  'CNAPS': Icons.currency_yuan_outlined,
  'FPS': Icons.flash_on_outlined,
  'CHATS': Icons.account_balance_wallet_outlined,
};

class _ChannelCard extends ConsumerWidget {
  const _ChannelCard({
    required this.channel,
    required this.regionIndex,
    required this.protocolIndex,
    required this.reorderIndex,
  });

  final Channel channel;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;
  final int reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _protocolColors[channel.transferProtocol] ?? GwpColors.actionPrimary;
    final icon = _protocolIcons[channel.transferProtocol] ?? Icons.swap_horiz_outlined;
    final enabled = channel.status == ChannelStatus.enabled;
    final isMaintenance = channel.status == ChannelStatus.maintenance;
    final protocolLabel = protocolDisplayLabel(protocolIndex, channel.transferProtocol);
    final regionSuffix = _channelRegionSuffix(channel, regionIndex);

    final limits = <String>[
      if (channel.singleLimit != null) '单笔 ≤ ${channel.singleLimit}',
      if (channel.dailyLimit != null) '日 ≤ ${channel.dailyLimit}',
      if (channel.limitCurrency != null) '(${channel.limitCurrency})',
    ];
    final fee = <String>[
      if (channel.feeRate != null) '费率 ${channel.feeRate}',
      if (channel.fixedFee != null) '固定 ${channel.fixedFee}',
    ];
    final meta = [
      '$protocolLabel$regionSuffix',
      if (fee.isNotEmpty) fee.join(' / '),
      if (limits.isNotEmpty) limits.join(' '),
    ].join(' · ');

    return ReorderableDelayedDragStartListener(
      index: reorderIndex,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/channels/${channel.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: GwpColors.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GwpColors.border, width: 0.5),
            ),
            child: Row(
              children: [
              // Left color bar
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: GwpSpacing.md),
              // Protocol icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: GwpSpacing.md),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: GwpSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${channel.name}$regionSuffix',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: GwpColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.isBuiltin) ...[
                            const SizedBox(width: GwpSpacing.xs),
                            const BuiltinBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: GwpColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: GwpSpacing.sm),
              // Status + Switch
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GwpStatusBadge(
                    label: isMaintenance
                        ? 'MAINT'
                        : (enabled ? 'ON' : 'OFF'),
                    variant: isMaintenance
                        ? StatusVariant.warning
                        : (enabled ? StatusVariant.positive : StatusVariant.muted),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 28,
                    child: Switch.adaptive(
                      value: enabled,
                      onChanged: isMaintenance
                          ? null
                          : (v) async {
                              final result = await ref
                                  .read(channelRepositoryProvider)
                                  .setStatus(
                                    channel.id,
                                    v
                                        ? ChannelStatus.enabled
                                        : ChannelStatus.disabled,
                                  );
                              if (result.isErr && ref.context.mounted) {
                                ScaffoldMessenger.of(ref.context).showSnackBar(
                                  SnackBar(
                                    content: Text('状态更新失败：${result.errorOrNull?.message ?? '未知错误'}'),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: GwpSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
