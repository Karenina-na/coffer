import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import 'channel_providers.dart';

class ChannelListPage extends ConsumerWidget {
  const ChannelListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelListProvider);
    return Scaffold(
      appBar: const AppTopBar(title: Text('转账通道')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/channels/new'),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('新建'),
      ),
      body: channels.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(channelListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const GwpEmptyState(
              icon: Icons.swap_horiz_outlined,
              title: '还没有通道',
              subtitle: '点击右下角 "新建" 添加转账通道策略',
            );
          }
          final enabled = list.where((c) => c.status == ChannelStatus.enabled).length;
          final protocols = list.map((c) => c.transferProtocol).toSet().length;
          return ListView(
            padding: const EdgeInsets.only(
              left: GwpSpacing.base,
              right: GwpSpacing.base,
              top: GwpSpacing.md,
              bottom: 80,
            ),
            children: [
              _SummaryHeader(
                total: list.length,
                enabled: enabled,
                protocols: protocols,
              ),
              const SizedBox(height: GwpSpacing.md),
              for (var i = 0; i < list.length; i++) ...[
                _ChannelCard(channel: list[i]),
                if (i < list.length - 1) const SizedBox(height: GwpSpacing.sm),
              ],
            ],
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
  'RTGS': Color(0xFFF59E0B),
  'FPS': Color(0xFFEC4899),
  'ONCHAIN': Color(0xFFF97316),
  'INTERNAL': Color(0xFF6B7280),
};

const _protocolIcons = <String, IconData>{
  'SWIFT': Icons.language_outlined,
  'ACH': Icons.account_balance_outlined,
  'SEPA': Icons.euro_outlined,
  'CNAPS': Icons.currency_yuan_outlined,
  'RTGS': Icons.speed_outlined,
  'FPS': Icons.flash_on_outlined,
  'ONCHAIN': Icons.link_outlined,
  'INTERNAL': Icons.swap_horiz_outlined,
};

class _ChannelCard extends ConsumerWidget {
  const _ChannelCard({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _protocolColors[channel.transferProtocol] ?? GwpColors.actionPrimary;
    final icon = _protocolIcons[channel.transferProtocol] ?? Icons.swap_horiz_outlined;
    final enabled = channel.status == ChannelStatus.enabled;
    final isMaintenance = channel.status == ChannelStatus.maintenance;

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
      channel.transferProtocol,
      if (fee.isNotEmpty) fee.join(' / '),
      if (limits.isNotEmpty) limits.join(' '),
    ].join(' · ');

    return Material(
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
                      Text(
                        channel.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GwpColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    );
  }
}
