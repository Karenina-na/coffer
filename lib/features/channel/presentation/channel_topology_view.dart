import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/horizontal_gesture_guard.dart';
import '../../../core/ui/protocol_display.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/dict_type.dart';
import '../../account/presentation/account_providers.dart';
import 'channel_providers.dart';

// ──────────────────────────────────────────────────────────────
// Topology data
// ──────────────────────────────────────────────────────────────

class _ChannelGroup {
  const _ChannelGroup({
    required this.channel,
    required this.accountIds,
    required this.accountMap,
  });
  final Channel channel;
  final List<String> accountIds;
  final Map<String, Account> accountMap;
}

final _topologyGraphProvider =
    FutureProvider.autoDispose<List<_ChannelGroup>>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final acLinks = await ref.watch(accountChannelListProvider.future);

  final channelAccounts = <String, Set<String>>{};
  for (final link in acLinks) {
    channelAccounts.putIfAbsent(link.channelId, () => {}).add(link.accountId);
  }

  final channelMap = {for (final c in channels) c.id: c};
  final accountMap = {for (final a in accounts) a.id: a};

  final groups = <_ChannelGroup>[];
  for (final entry in channelAccounts.entries) {
    final channel = channelMap[entry.key];
    if (channel == null || entry.value.length < 2) continue;
    final sortedIds = entry.value.toList()
      ..sort((a, b) {
        final aName = accountMap[a]?.institutionName ?? a;
        final bName = accountMap[b]?.institutionName ?? b;
        return aName.compareTo(bName);
      });
    groups.add(_ChannelGroup(
      channel: channel,
      accountIds: sortedIds,
      accountMap: accountMap,
    ));
  }

  // Sort by number of connected accounts (desc), then channel name
  groups.sort((a, b) {
    final c = b.accountIds.length.compareTo(a.accountIds.length);
    if (c != 0) return c;
    return a.channel.name.compareTo(b.channel.name);
  });

  return groups;
});

// ──────────────────────────────────────────────────────────────
// Collapsible topology section
// ──────────────────────────────────────────────────────────────

class ChannelTopologySection extends ConsumerStatefulWidget {
  const ChannelTopologySection({super.key, this.sourceId, this.targetId});

  final String? sourceId;
  final String? targetId;

  @override
  ConsumerState<ChannelTopologySection> createState() =>
      _ChannelTopologySectionState();
}

class _ChannelTopologySectionState
    extends ConsumerState<ChannelTopologySection> {
  bool _expanded = false;
  bool _didAutoExpand = false;

  @override
  void didUpdateWidget(covariant ChannelTopologySection old) {
    super.didUpdateWidget(old);
    if (!_didAutoExpand &&
        widget.sourceId != null &&
        widget.targetId != null) {
      _didAutoExpand = true;
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GwpSpacing.sm),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.hub_outlined,
                  size: 18,
                  color: GwpColors.actionPrimary,
                ),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  '通道拓扑',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: GwpColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: GwpColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: GwpSpacing.sm),
          _TopologyGraph(
            sourceId: widget.sourceId,
            targetId: widget.targetId,
          ),
        ],
      ],
    );
  }
}

class _TopologyGraph extends ConsumerWidget {
  const _TopologyGraph({this.sourceId, this.targetId});

  final String? sourceId;
  final String? targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_topologyGraphProvider);
    return async.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: GwpColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GwpColors.border, width: 0.5),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GwpColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GwpColors.border, width: 0.5),
        ),
        child: Text('加载失败: ${errorToMessage(e)}',
            style: const TextStyle(color: GwpColors.negative, fontSize: 12)),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GwpColors.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GwpColors.border, width: 0.5),
            ),
            child: const Text(
              '至少需要两个账户绑定同一通道',
              style: TextStyle(color: GwpColors.textMuted, fontSize: 12),
            ),
          );
        }
        final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};
        final protocolEntries =
            ref.watch(dictEntriesProvider(DictType.transferProtocol)).value ??
            const [];
        final ProtocolIndex protocolIndex = {
          for (final entry in protocolEntries) entry.code: entry,
        };
        return _TopologyCardList(
          groups: groups,
          regionIndex: regionIndex,
          protocolIndex: protocolIndex,
          sourceId: sourceId,
          targetId: targetId,
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Channel-centric card layout
// ──────────────────────────────────────────────────────────────

class _TopologyCardList extends StatelessWidget {
  const _TopologyCardList({
    required this.groups,
    required this.regionIndex,
    required this.protocolIndex,
    this.sourceId,
    this.targetId,
  });

  final List<_ChannelGroup> groups;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;
  final String? sourceId;
  final String? targetId;

  @override
  Widget build(BuildContext context) {
    return HorizontalGestureGuard(
      child: Column(
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            _ChannelCard(
              group: groups[i],
              regionIndex: regionIndex,
              protocolIndex: protocolIndex,
              sourceId: sourceId,
              targetId: targetId,
            ),
            if (i < groups.length - 1) const SizedBox(height: GwpSpacing.sm),
          ],
        ],
      ),
    );
  }
}

const _protocolColors = <String, Color>{
  'SWIFT': Color(0xFF64748B),
  'ACH': Color(0xFF22C55E),
  'SEPA': Color(0xFF38BDF8),
  'CNAPS': Color(0xFFEF4444),
  'FPS': Color(0xFFF59E0B),
  'CHATS': Color(0xFF14B8A6),
  'CIPS': Color(0xFFEF4444),
};

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.group,
    required this.regionIndex,
    required this.protocolIndex,
    this.sourceId,
    this.targetId,
  });

  final _ChannelGroup group;
  final RegionIndex regionIndex;
  final ProtocolIndex protocolIndex;
  final String? sourceId;
  final String? targetId;

  @override
  Widget build(BuildContext context) {
    final ch = group.channel;
    final protoColor =
        _protocolColors[ch.transferProtocol] ?? GwpColors.actionPrimary;
    final protoName = protocolDisplayName(protocolIndex, ch.transferProtocol);
    final hasBoth = sourceId != null &&
        targetId != null &&
        group.accountIds.contains(sourceId) &&
        group.accountIds.contains(targetId);

    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBoth
              ? GwpColors.positive.withValues(alpha: 0.4)
              : GwpColors.border,
          width: hasBoth ? 1 : 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GwpSpacing.md,
              vertical: GwpSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: hasBoth
                  ? GwpColors.positiveBg
                  : protoColor.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasBoth ? GwpColors.positive : protoColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Expanded(
                  child: Text(
                    ch.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasBoth ? GwpColors.positive : GwpColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: protoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$protoName · ${group.accountIds.length} 账户',
                    style: TextStyle(
                      fontSize: 10,
                      color: protoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Account chips row
          Padding(
            padding: const EdgeInsets.all(GwpSpacing.sm),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in group.accountIds)
                  _AccountChip(
                    account: group.accountMap[id],
                    regionIndex: regionIndex,
                    highlighted: id == sourceId || id == targetId,
                    role: id == sourceId
                        ? '源'
                        : (id == targetId ? '目标' : null),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.account,
    required this.regionIndex,
    this.highlighted = false,
    this.role,
  });

  final Account? account;
  final RegionIndex regionIndex;
  final bool highlighted;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final name = account?.institutionName ?? '未知';
    final region = account != null
        ? regionLabel(regionIndex, account!.sovereigntyRegion)
        : '';
    final borderColor = highlighted
        ? role == '源'
            ? GwpColors.negative
            : GwpColors.positive
        : GwpColors.border;
    final bgColor = highlighted
        ? (role == '源' ? GwpColors.negativeBg : GwpColors.positiveBg)
        : GwpColors.surface2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.sm, vertical: GwpSpacing.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: highlighted ? 1 : 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (role != null) ...[
            Text(
              role!,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: highlighted
                    ? (role == '源' ? GwpColors.negative : GwpColors.positive)
                    : GwpColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
              color: highlighted ? borderColor : GwpColors.textPrimary,
            ),
          ),
          if (region.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              region,
              style: TextStyle(
                fontSize: 8,
                color: highlighted ? borderColor : GwpColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
