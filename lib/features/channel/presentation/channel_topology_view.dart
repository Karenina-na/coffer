import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/account.dart';
import '../../account/presentation/account_providers.dart';
import 'channel_providers.dart';

// ──────────────────────────────────────────────────────────────
// Topology data provider
// ──────────────────────────────────────────────────────────────

class _TopoEdge {
  const _TopoEdge({
    required this.sourceId,
    required this.targetId,
    required this.channelName,
  });
  final String sourceId;
  final String targetId;
  final String channelName;
}

class _TopologyData {
  const _TopologyData({
    required this.accounts,
    required this.edges,
    required this.accountMap,
  });
  final List<Account> accounts;
  final List<_TopoEdge> edges;
  final Map<String, Account> accountMap;
}

final _topologyGraphProvider =
    FutureProvider.autoDispose<_TopologyData>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final acLinks = await ref.watch(accountChannelListProvider.future);

  final channelAccounts = <String, Set<String>>{};
  for (final link in acLinks) {
    channelAccounts.putIfAbsent(link.channelId, () => {}).add(link.accountId);
  }

  final channelMap = {for (final c in channels) c.id: c};
  final accountMap = {for (final a in accounts) a.id: a};

  final edges = <_TopoEdge>[];
  final seenPairs = <(String, String)>{};
  for (final entry in channelAccounts.entries) {
    final acctIds = entry.value.toList();
    final channel = channelMap[entry.key];
    if (channel == null || acctIds.length < 2) continue;
    for (var i = 0; i < acctIds.length; i++) {
      for (var j = i + 1; j < acctIds.length; j++) {
        final a = acctIds[i];
        final b = acctIds[j];
        final pair = a.compareTo(b) < 0 ? (a, b) : (b, a);
        if (seenPairs.add(pair)) {
          edges.add(_TopoEdge(
            sourceId: a,
            targetId: b,
            channelName: channel.name,
          ));
        }
      }
    }
  }

  return _TopologyData(
    accounts: accounts,
    edges: edges,
    accountMap: accountMap,
  );
});

// ──────────────────────────────────────────────────────────────
// Collapsible topology section widget
// ──────────────────────────────────────────────────────────────

class ChannelTopologySection extends ConsumerStatefulWidget {
  const ChannelTopologySection({super.key});

  @override
  ConsumerState<ChannelTopologySection> createState() =>
      _ChannelTopologySectionState();
}

class _ChannelTopologySectionState
    extends ConsumerState<ChannelTopologySection> {
  bool _expanded = false;

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
          const _TopologyGraph(),
        ],
      ],
    );
  }
}

class _TopologyGraph extends ConsumerWidget {
  const _TopologyGraph();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_topologyGraphProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(GwpSpacing.base),
        child: Text('加载失败: ${errorToMessage(e)}',
            style: const TextStyle(color: GwpColors.negative, fontSize: 12)),
      ),
      data: (data) {
        if (data.accounts.length < 2 || data.edges.isEmpty) {
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
        return _GraphContainer(data: data);
      },
    );
  }
}

class _GraphContainer extends StatelessWidget {
  const _GraphContainer({required this.data});
  final _TopologyData data;

  @override
  Widget build(BuildContext context) {
    final graph = Graph();
    final nodeMap = <String, Node>{};

    for (final acct in data.accounts) {
      final node = Node.Id(acct.id);
      nodeMap[acct.id] = node;
      graph.addNode(node);
    }

    final edgePaint = Paint()
      ..color = GwpColors.actionPrimary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in data.edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src != null && tgt != null) {
        graph.addEdge(src, tgt, paint: edgePaint);
      }
    }

    final config = FruchtermanReingoldConfiguration(
      iterations: 300,
      repulsionRate: 0.6,
    );
    final algorithm = FruchtermanReingoldAlgorithm(config);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: GraphView(
        graph: graph,
        algorithm: algorithm,
        animated: false,
        builder: (Node node) {
          final id = (node.key as ValueKey).value as String;
          final acct = data.accountMap[id];
          return _NodeChip(
            label: acct?.institutionName ?? id.substring(0, 6),
            region: acct?.sovereigntyRegion ?? '',
          );
        },
      ),
    );
  }
}

class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.label, required this.region});
  final String label;
  final String region;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.sm,
        vertical: GwpSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: GwpColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: GwpColors.actionPrimary.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: GwpColors.textPrimary,
            ),
          ),
          if (region.isNotEmpty)
            Text(
              region,
              style: const TextStyle(
                fontSize: 8,
                color: GwpColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
