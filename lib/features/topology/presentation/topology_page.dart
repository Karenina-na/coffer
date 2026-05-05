import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/region_meta.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_providers.dart';
import '../../channel/presentation/channel_providers.dart';
import '../../../data/providers/dict_providers.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _TopoNode {
  _TopoNode({required this.id, required this.label, required this.kind, this.parentId, this.region, this.color});
  final String id;
  final String label;
  final _NodeKind kind;
  final String? parentId;
  final String? region;
  final Color? color;
}

enum _NodeKind { account, asset, channel, card }

class _TopoEdge {
  _TopoEdge({required this.fromId, required this.toId});
  final String fromId;
  final String toId;
}

class _TopologyModel {
  _TopologyModel({required this.nodes, required this.edges});
  final List<_TopoNode> nodes;
  final List<_TopoEdge> edges;
}

// ---------------------------------------------------------------------------
// Provider — assembles all entities into a topology model
// ---------------------------------------------------------------------------

final _topologyModelProvider = FutureProvider.autoDispose<_TopologyModel>((ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final cards = await ref.watch(cardListProvider.future);
  final acLinks = await ref.watch(accountChannelListProvider.future);
  final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};

  final nodes = <_TopoNode>[];
  final edges = <_TopoEdge>[];

  const typeColors = <String, Color>{
    'stock': Color(0xFF64748B),
    'fund': Color(0xFF22C55E),
    'bond': Color(0xFFF59E0B),
    'crypto': Color(0xFFEC4899),
    'cd': Color(0xFFA78BFA),
    'fxAsset': Color(0xFF38BDF8),
  };

  const cardColors = <String, Color>{
    'Visa': Color(0xFF1A1F71),
    'Mastercard': Color(0xFFEB001B),
    'UnionPay': Color(0xFFD81E2B),
  };

  // 1. Account nodes
  for (final a in accounts) {
    nodes.add(_TopoNode(
      id: 'acc:${a.id}',
      label: a.institutionName,
      kind: _NodeKind.account,
      region: a.sovereigntyRegion,
      color: regionColor(regionIndex, a.sovereigntyRegion),
    ));
  }

  // 2. Asset nodes (child of account)
  for (final a in assets) {
    nodes.add(_TopoNode(
      id: 'ast:${a.id}',
      label: a.assetCode ?? a.id.substring(0, 6),
      kind: _NodeKind.asset,
      parentId: 'acc:${a.accountId}',
      color: typeColors[a.assetType.name] ?? GwpColors.textMuted,
    ));
    edges.add(_TopoEdge(fromId: 'acc:${a.accountId}', toId: 'ast:${a.id}'));
  }

  // 3. Channel nodes
  for (final c in channels) {
    final statusColor = c.status.name == 'enabled'
        ? GwpColors.actionPrimary
        : c.status.name == 'disabled'
            ? GwpColors.textMuted
            : GwpColors.warning;
    nodes.add(_TopoNode(
      id: 'ch:${c.id}',
      label: c.name,
      kind: _NodeKind.channel,
      color: statusColor,
    ));
  }

  // 4. Card nodes (child of account)
  for (final c in cards) {
    nodes.add(_TopoNode(
      id: 'crd:${c.id}',
      label: '${c.cardOrganization} ${c.cardNoMasked.length > 4 ? c.cardNoMasked.substring(c.cardNoMasked.length - 4) : c.cardNoMasked}',
      kind: _NodeKind.card,
      parentId: 'acc:${c.accountId}',
      color: cardColors[c.cardOrganization] ?? GwpColors.textSecondary,
    ));
    edges.add(_TopoEdge(fromId: 'acc:${c.accountId}', toId: 'crd:${c.id}'));
  }

  // 5. Account-Channel edges
  for (final link in acLinks) {
    edges.add(_TopoEdge(fromId: 'acc:${link.accountId}', toId: 'ch:${link.channelId}'));
  }

  return _TopologyModel(nodes: nodes, edges: edges);
});

// ---------------------------------------------------------------------------
// Filter state — Notifier pattern (Riverpod 3.x)
// ---------------------------------------------------------------------------

enum _EntityFilter { account, asset, channel, card }

class _FiltersNotifier extends Notifier<Set<_EntityFilter>> {
  @override
  Set<_EntityFilter> build() => {_EntityFilter.account, _EntityFilter.asset, _EntityFilter.channel, _EntityFilter.card};

  void toggle(_EntityFilter f, bool selected) {
    final s = Set<_EntityFilter>.from(state);
    selected ? s.add(f) : s.remove(f);
    state = s;
  }
}

final _filtersProvider = NotifierProvider<_FiltersNotifier, Set<_EntityFilter>>(_FiltersNotifier.new);

class _ActiveOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final _activeOnlyProvider = NotifierProvider<_ActiveOnlyNotifier, bool>(_ActiveOnlyNotifier.new);

enum _LayoutMode { force, tree }

class _LayoutModeNotifier extends Notifier<_LayoutMode> {
  @override
  _LayoutMode build() => _LayoutMode.force;

  void toggle() => state = state == _LayoutMode.force ? _LayoutMode.tree : _LayoutMode.force;
}

final _layoutModeProvider = NotifierProvider<_LayoutModeNotifier, _LayoutMode>(_LayoutModeNotifier.new);

// ---------------------------------------------------------------------------
// Styles (using design token fonts)
// ---------------------------------------------------------------------------

const _kCaption = TextStyle(fontFamily: GwpTypo.uiFont, fontSize: 11, height: 1.3);
const _kHeading = TextStyle(fontFamily: GwpTypo.uiFont, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class TopologyPage extends ConsumerWidget {
  const TopologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: GwpColors.canvas,
      appBar: AppBar(
        title: Text('全景关系图', style: _kHeading.copyWith(color: GwpColors.textPrimary)),
        backgroundColor: GwpColors.surface1,
        foregroundColor: GwpColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '切换布局',
            onPressed: () => ref.read(_layoutModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: const Column(
        children: [
          _FilterBar(),
          _StatsBar(),
          Expanded(child: _GraphBody()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(_filtersProvider);
    final activeOnly = ref.watch(_activeOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.md, vertical: GwpSpacing.sm),
      color: GwpColors.surface1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _EntityFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: GwpSpacing.sm),
                child: FilterChip(
                  label: Text(_filterLabel(f)),
                  selected: filters.contains(f),
                  onSelected: (v) => ref.read(_filtersProvider.notifier).toggle(f, v),
                  selectedColor: GwpColors.actionPrimary.withValues(alpha: 0.2),
                  checkmarkColor: GwpColors.actionPrimary,
                  labelStyle: _kCaption.copyWith(color: GwpColors.textPrimary),
                  backgroundColor: GwpColors.surface2,
                  side: BorderSide.none,
                ),
              ),
            FilterChip(
              label: const Text('仅活跃'),
              selected: activeOnly,
              onSelected: (v) => ref.read(_activeOnlyProvider.notifier).set(v),
              selectedColor: GwpColors.positive.withValues(alpha: 0.2),
              checkmarkColor: GwpColors.positive,
              labelStyle: _kCaption.copyWith(color: GwpColors.textPrimary),
              backgroundColor: GwpColors.surface2,
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(_EntityFilter f) => switch (f) {
        _EntityFilter.account => '账户',
        _EntityFilter.asset => '资产',
        _EntityFilter.channel => '通道',
        _EntityFilter.card => '卡片',
      };
}

// ---------------------------------------------------------------------------
// Stats bar
// ---------------------------------------------------------------------------

class _StatsBar extends ConsumerWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(_topologyModelProvider);
    return model.when(
      data: (m) {
        int acc = 0, ast = 0, ch = 0, crd = 0;
        for (final n in m.nodes) {
          switch (n.kind) {
            case _NodeKind.account:
              acc++;
            case _NodeKind.asset:
              ast++;
            case _NodeKind.channel:
              ch++;
            case _NodeKind.card:
              crd++;
          }
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.md, vertical: GwpSpacing.xs),
          color: GwpColors.surface1,
          child: Text(
            '$acc 账户 · $ast 资产 · $ch 通道 · $crd 卡片',
            style: _kCaption.copyWith(color: GwpColors.textMuted),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Graph body
// ---------------------------------------------------------------------------

class _GraphBody extends ConsumerWidget {
  const _GraphBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(_topologyModelProvider);
    final filters = ref.watch(_filtersProvider);
    final layoutMode = ref.watch(_layoutModeProvider);

    return modelAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: GwpColors.actionPrimary)),
      error: (e, _) => GwpEmptyState.error(
        message: '加载失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(_topologyModelProvider),
      ),
      data: (model) {
        final visibleKinds = <_NodeKind>{};
        for (final f in filters) {
          visibleKinds.add(switch (f) {
            _EntityFilter.account => _NodeKind.account,
            _EntityFilter.asset => _NodeKind.asset,
            _EntityFilter.channel => _NodeKind.channel,
            _EntityFilter.card => _NodeKind.card,
          });
        }
        visibleKinds.add(_NodeKind.account);

        final visibleNodes = model.nodes.where((n) => visibleKinds.contains(n.kind)).toList();
        final visibleIds = visibleNodes.map((n) => n.id).toSet();
        final visibleEdges = model.edges.where((e) => visibleIds.contains(e.fromId) && visibleIds.contains(e.toId)).toList();

        if (visibleNodes.isEmpty) {
          return const GwpEmptyState(
            icon: Icons.hub_outlined,
            title: '暂无实体',
            subtitle: '按顶部筛选项调整过滤，或在账户 / 资产 / 通道 / 卡片页面新增记录',
          );
        }

        return _TopologyGraphView(
          nodes: visibleNodes,
          edges: visibleEdges,
          layoutMode: layoutMode,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// GraphView widget
// ---------------------------------------------------------------------------

class _TopologyGraphView extends StatelessWidget {
  const _TopologyGraphView({required this.nodes, required this.edges, required this.layoutMode});

  final List<_TopoNode> nodes;
  final List<_TopoEdge> edges;
  final _LayoutMode layoutMode;

  @override
  Widget build(BuildContext context) {
    final graph = Graph()..isTree = layoutMode == _LayoutMode.tree;
    final nodeMap = <String, Node>{};

    for (final n in nodes) {
      final node = Node.Id(n.id);
      graph.addNode(node);
      nodeMap[n.id] = node;
    }

    for (final e in edges) {
      final from = nodeMap[e.fromId];
      final to = nodeMap[e.toId];
      if (from != null && to != null) {
        graph.addEdge(from, to);
      }
    }

    final Algorithm algorithm;
    if (layoutMode == _LayoutMode.tree) {
      algorithm = BuchheimWalkerAlgorithm(
        BuchheimWalkerConfiguration()
          ..siblingSeparation = 60
          ..levelSeparation = 80
          ..subtreeSeparation = 80
          ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM,
        TreeEdgeRenderer(BuchheimWalkerConfiguration()),
      );
    } else {
      final config = FruchtermanReingoldConfiguration(
        iterations: 400,
        repulsionRate: 0.65,
      );
      algorithm = FruchtermanReingoldAlgorithm(config);
    }

    final topoNodeMap = {for (final n in nodes) n.id: n};

    final edgePaint = Paint()
      ..color = GwpColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.3,
      maxScale: 3.0,
      child: GraphView(
        graph: graph,
        algorithm: algorithm,
        paint: edgePaint,
        builder: (Node node) {
          final id = node.key!.value as String;
          final tNode = topoNodeMap[id];
          if (tNode == null) return const SizedBox.shrink();
          return _NodeWidget(node: tNode);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Node widget — visual encoding per node kind
// ---------------------------------------------------------------------------

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({required this.node});
  final _TopoNode node;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onNodeTap(context, node),
      child: switch (node.kind) {
        _NodeKind.account => _AccountNodeWidget(node: node),
        _NodeKind.asset => _SmallNodeWidget(node: node, shape: BoxShape.rectangle),
        _NodeKind.channel => _ChannelNodeWidget(node: node),
        _NodeKind.card => _CardNodeWidget(node: node),
      },
    );
  }

  static void _onNodeTap(BuildContext context, _TopoNode node) {
    final rawId = node.id.split(':').last;
    switch (node.kind) {
      case _NodeKind.account:
        context.push('/accounts/$rawId');
      case _NodeKind.asset:
        context.push('/assets/$rawId');
      case _NodeKind.channel:
      case _NodeKind.card:
        break; // no detail page for these yet
    }
  }
}

class _AccountNodeWidget extends StatelessWidget {
  const _AccountNodeWidget({required this.node});
  final _TopoNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GwpSpacing.sm),
      decoration: BoxDecoration(
        color: (node.color ?? GwpColors.actionPrimary).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: node.color ?? GwpColors.actionPrimary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.label.length > 4 ? node.label.substring(0, 4) : node.label,
            style: _kCaption.copyWith(color: GwpColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          if (node.region != null)
            Text(node.region!, style: _kCaption.copyWith(color: GwpColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

class _SmallNodeWidget extends StatelessWidget {
  const _SmallNodeWidget({required this.node, required this.shape});
  final _TopoNode node;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.sm, vertical: GwpSpacing.xs),
      decoration: BoxDecoration(
        color: (node.color ?? GwpColors.textMuted).withValues(alpha: 0.15),
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(4) : null,
        shape: shape,
        border: Border.all(color: node.color ?? GwpColors.textMuted, width: 1),
      ),
      child: Text(
        node.label,
        style: _kCaption.copyWith(color: GwpColors.textPrimary, fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ChannelNodeWidget extends StatelessWidget {
  const _ChannelNodeWidget({required this.node});
  final _TopoNode node;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        padding: const EdgeInsets.all(GwpSpacing.sm),
        decoration: BoxDecoration(
          color: (node.color ?? GwpColors.actionPrimary).withValues(alpha: 0.15),
          border: Border.all(color: node.color ?? GwpColors.actionPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Transform.rotate(
          angle: -0.785398,
          child: Text(
            node.label,
            style: _kCaption.copyWith(color: GwpColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CardNodeWidget extends StatelessWidget {
  const _CardNodeWidget({required this.node});
  final _TopoNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GwpSpacing.sm, vertical: GwpSpacing.xs),
      decoration: BoxDecoration(
        color: (node.color ?? GwpColors.textSecondary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: node.color ?? GwpColors.textSecondary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 12, color: node.color ?? GwpColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            node.label,
            style: _kCaption.copyWith(color: GwpColors.textPrimary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
