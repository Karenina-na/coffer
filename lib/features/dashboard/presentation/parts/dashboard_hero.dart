part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Shared: Section title
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: GwpSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GwpColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// A. Hero: Dot-Matrix 2D World Map
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ── Map layer filters ─────────────────────────────────────────

enum _MapLayer { edges, regionDots, labels, glow }

enum _MapScope { country, aggregate }

class _MapPreset {
  const _MapPreset(this.label, this.layers);
  final String label;
  final Set<_MapLayer> layers;
}

const _kPresets = [
  _MapPreset('全部', {
    _MapLayer.edges,
    _MapLayer.regionDots,
    _MapLayer.labels,
    _MapLayer.glow
  }),
  _MapPreset('简洁', {_MapLayer.regionDots, _MapLayer.glow}),
  _MapPreset('通道图', {_MapLayer.edges, _MapLayer.regionDots}),
];

const _kDefaultPresetIdx = 0;

// ── Region → Continent mapping, display names, colors, coordinates ───────────
// All data is now centralised in core/ui/region_meta.dart (kRegions).
// Use regionMetaOf(code), regionLabel(code), regionColor(code),
// kContinentList, and kContinentColors from that file.

// ── Map node / edge filter helpers ───────────────────────────
// Extracted as library-visible functions so unit tests can exercise them
// without requiring a full widget tree.

/// Returns the subset of [nodes] that belong to at least one continent in
/// [visibleContinents].  Nodes whose [MapNode.regionCode] is not registered in
/// [kRegions] are **hidden** when a filter is active (not shown as
/// unclassified). When [visibleContinents] is `null`, all nodes are returned.
@visibleForTesting
List<MapNode> heroFilterNodes(
    RegionIndex regionIndex,
    List<MapNode> nodes,
    Set<String>? visibleContinents) {
  if (visibleContinents == null) return nodes;
  return nodes.where((n) {
    final cont = regionMetaOf(regionIndex, n.regionCode)?.continent;
    return cont != null && visibleContinents.contains(cont);
  }).toList();
}

/// Returns the subset of [edges] where both endpoints are in
/// [visibleRegionCodes].
@visibleForTesting
List<MapEdge> heroFilterEdges(
    List<MapEdge> edges, Set<String> visibleRegionCodes) {
  return edges
      .where((e) =>
          visibleRegionCodes.contains(e.fromRegion) &&
          visibleRegionCodes.contains(e.toRegion))
      .toList();
}

// ── Land geometry — generated from assets/world.svg ───────────

// ── Dot-matrix land bitmap (pre-computed, lazy) ───────────────

const _dotCols = 88;
const _dotRows = 42;

final _landSurface = ProjectedLandSurface.forGrid(cols: _dotCols, rows: _dotRows);

@visibleForTesting
bool heroLandContainsPoint(double px, double py) => containsRawLand(px, py);

@visibleForTesting
bool heroProjectedLandContainsPoint(double px, double py) =>
    _landSurface.containsProjected(px, py);

@visibleForTesting
int heroLandCellCount() => _landSurface.cellCount();


@visibleForTesting
(double, double) heroWarpCoords((double, double) norm) {
  return FinanceMapProjection.warpCoords(norm);
}

@visibleForTesting
double heroProjectDepth((double, double) norm) {
  return FinanceMapProjection.projectDepth(norm);
}

@visibleForTesting
Offset heroProjectPoint(Size size, (double, double) norm) {
  return FinanceMapProjection.projectPoint(size, norm);
}

@visibleForTesting
List<Offset> heroProjectGuide(Size size, double yNorm, {int samples = 24}) {
  return FinanceMapProjection.projectGuide(size, yNorm, samples: samples);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Hero widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridMapHero extends ConsumerStatefulWidget {
  const _GridMapHero();

  @override
  ConsumerState<_GridMapHero> createState() => _GridMapHeroState();
}

class _GridMapHeroState extends ConsumerState<_GridMapHero> {
  _MapScope _scope = _MapScope.country;

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(
      _scope == _MapScope.country
          ? nodeMapDataProvider
          : nodeMapAggregateDataProvider,
    );
    final regionIndex =
        ref.watch(regionMetaIndexProvider).value ?? const {};

    return mapAsync.when(
      loading: () => const SizedBox(
        height: 210,
        child: Center(
          child: CircularProgressIndicator(
            color: GwpColors.actionPrimary,
            strokeWidth: 1.5,
          ),
        ),
      ),
      error: (_, _) => const SizedBox(height: 210),
      data: (mapData) => _GridMapContent(
        mapData: mapData,
        regionIndex: regionIndex,
        scope: _scope,
        onScopeChanged: (scope) => setState(() => _scope = scope),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Map content (stateful: filter + selection)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridMapContent extends StatefulWidget {
  const _GridMapContent({
    required this.mapData,
    required this.regionIndex,
    required this.scope,
    required this.onScopeChanged,
  });
  final NodeMapData mapData;
  final RegionIndex regionIndex;
  final _MapScope scope;
  final ValueChanged<_MapScope> onScopeChanged;

  @override
  State<_GridMapContent> createState() => _GridMapContentState();
}

class _GridMapContentState extends State<_GridMapContent>
    with SingleTickerProviderStateMixin {
  int _presetIdx = _kDefaultPresetIdx;
  Set<_MapLayer> _layers = Set.from(_kPresets[_kDefaultPresetIdx].layers);

  // null = all continents visible
  Set<String>? _visibleContinents;

  MapNode? _selectedNode;
  Offset? _selectedOffset;

  // Radar-ping animation (loops)
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Derived: visible nodes based on continent filter ─────────
  List<MapNode> get _visibleNodes =>
      heroFilterNodes(widget.regionIndex, widget.mapData.nodes, _visibleContinents);

  // ── Continents that actually have nodes in current data ──────
  Set<String> get _dataContinents => widget.mapData.nodes
      .map((n) => regionMetaOf(widget.regionIndex, n.regionCode)?.continent)
      .whereType<String>()
      .toSet();

  void _openFilterSheet() {
    final dataContinents = _dataContinents;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GwpColors.surface1,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        initialPresetIdx: _presetIdx,
        initialLayers: _layers,
        initialContinents: _visibleContinents ?? dataContinents,
        availableContinents: dataContinents,
        initialScope: widget.scope,
        onChanged: (idx, layers, continents, scope) {
          setState(() {
            _presetIdx = idx;
            _layers = Set.from(layers);
            _visibleContinents =
                continents.length == dataContinents.length
                    ? null
                    : Set.from(continents);
          });
          if (widget.scope != scope) {
            widget.onScopeChanged(scope);
          }
        },
      ),
    );
  }

  void _onMapTap(TapUpDetails details, Size canvasSize) {
    final tap = details.localPosition;
    const hitRadius = 18.0;

    MapNode? hit;
    double bestDist = hitRadius;
    Offset? hitOffset;

    if (_layers.contains(_MapLayer.regionDots)) {
      for (final node in _visibleNodes) {
        final coords = regionMetaOf(widget.regionIndex, node.regionCode)?.mapCoords;
        if (coords == null) continue;
        final dotPos = FinanceMapProjection.projectPoint(canvasSize, coords);
        final dist = (tap - dotPos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          hit = node;
          hitOffset = dotPos;
        }
      }
    }

    setState(() {
      if (hit != null && hit == _selectedNode) {
        _selectedNode = null;
        _selectedOffset = null;
      } else {
        if (hit != null) HapticFeedback.selectionClick();
        _selectedNode = hit;
        _selectedOffset = hitOffset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _visibleNodes;
    // Compute edges inline using the already-resolved node set — avoids
    // calling _visibleNodes a second time inside a separate getter.
    final edges = _visibleContinents == null
        ? widget.mapData.edges
        : heroFilterEdges(
            widget.mapData.edges,
            nodes.map((n) => n.regionCode).toSet(),
          );

    // Pre-compute painter data that depends only on `nodes`, not on the
    // animation value. The AnimatedBuilder.builder closure captures these
    // variables so they are computed once per build() call, not per frame.
    final forcedCells = <(int, int)>{};
    final activeProjected = <(double, double)>[];
    for (final n in nodes) {
      final c = regionMetaOf(widget.regionIndex, n.regionCode)?.mapCoords;
      if (c == null) continue;
      final projected = heroProjectPoint(const Size(1, 1), c);
      forcedCells.add((
        (projected.dx * _dotCols).floor().clamp(0, _dotCols - 1),
        (projected.dy * _dotRows).floor().clamp(0, _dotRows - 1),
      ));
      activeProjected.add((projected.dx, projected.dy));
    }

    final regionCount = nodes.length;
    final accountCount = nodes.fold(0, (s, n) => s + n.accountCount);
    final channelCount = edges.length;

    final totalValue = nodes.fold<double>(0, (s, n) => s + n.value);
    final topNode = nodes.isEmpty
        ? null
        : nodes.reduce((a, b) => a.value >= b.value ? a : b);
    final topPct = totalValue > 0 && topNode != null
        ? (topNode.value / totalValue * 100)
        : 0.0;

    final channelsByRegion = <String, int>{};
    for (final e in edges) {
      channelsByRegion.update(e.fromRegion, (v) => v + e.channelCount,
          ifAbsent: () => e.channelCount);
      channelsByRegion.update(e.toRegion, (v) => v + e.channelCount,
          ifAbsent: () => e.channelCount);
    }
    final legendContinents = orderedContinentLabels(
      nodes
          .map((n) => regionMetaOf(widget.regionIndex, n.regionCode)?.continent)
          .whereType<String>(),
    );

    // Active filter indicator count (how many layers are disabled)
    final allLayerCount = _kPresets[0].layers.length;
    final hiddenCount = allLayerCount - _layers.length;
    final scopeFiltered = _visibleContinents != null;
    final filterActive = hiddenCount > 0 || scopeFiltered;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Map canvas ────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final canvasWidth = constraints.maxWidth;
          final canvasHeight = (canvasWidth * 0.49).clamp(176.0, 204.0);
          final canvasSize = Size(canvasWidth, canvasHeight);
          final compactCanvas = canvasWidth < 430;

          return SizedBox(
            height: canvasHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                GestureDetector(
                  onTapUp: (d) => _onMapTap(d, canvasSize),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) => CustomPaint(
                      size: canvasSize,
                      painter: _DotWorldPainter(
                        nodes: nodes,
                        edges: edges,
                        layers: _layers,
                        selectedRegion: _selectedNode?.regionCode,
                        pulseValue: _pulseCtrl.value,
                        forcedCells: forcedCells,
                        activeProjected: activeProjected,
                        regionIndex: widget.regionIndex,
                      ),
                    ),
                  ),
                ),

                // Map title watermark — top-left
                Positioned(
                  top: 8,
                  left: 10,
                  child: Text(
                    widget.scope == _MapScope.country ? '全球持仓分布' : '全球区域分布',
                    style: TextStyle(
                      color: GwpColors.textMuted.withValues(alpha: 0.28),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                // Continent color legend — above bottom controls
                if (_layers.contains(_MapLayer.regionDots) && !compactCanvas)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 26,
                    child: IgnorePointer(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 3,
                        runSpacing: 2,
                        children: legendContinents
                            .map((c) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(right: 3),
                                      decoration: BoxDecoration(
                                        color: (kContinentColors[c] ??
                                                GwpColors.actionPrimary)
                                            .withValues(alpha: 0.70),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                      c,
                                      style: TextStyle(
                                        color: GwpColors.textMuted
                                            .withValues(alpha: 0.42),
                                        fontSize: 7.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),

                // Tap hint — bottom-right, only when no selection
                if (_selectedNode == null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: Text(
                        '轻触节点查看详情',
                        style: TextStyle(
                          color:
                              GwpColors.textMuted.withValues(alpha: 0.30),
                          fontSize: 8.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // Empty state when continent filter hides all nodes
                if (nodes.isEmpty)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public_off_rounded,
                            size: 22,
                            color: GwpColors.textMuted
                                .withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '当前筛选无持仓地区',
                            style: TextStyle(
                              color: GwpColors.textMuted
                                  .withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Filter button — bottom-left
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: filterActive
                            ? GwpColors.actionPrimary.withValues(alpha: 0.18)
                            : GwpColors.surface2.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: filterActive
                              ? GwpColors.actionPrimary.withValues(alpha: 0.55)
                              : GwpColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 11,
                            color: filterActive
                                ? GwpColors.actionPrimary
                                : GwpColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _presetIdx >= 0
                                ? _kPresets[_presetIdx].label
                                : '自定义',
                            style: TextStyle(
                              fontSize: 10,
                              color: filterActive
                                  ? GwpColors.actionPrimary
                                  : GwpColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (filterActive) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: GwpColors.actionPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Node info popup
                if (_selectedNode != null && _selectedOffset != null)
                  _NodeInfoPopup(
                    key: ValueKey(_selectedNode!.regionCode),
                    node: _selectedNode!,
                    dotOffset: _selectedOffset!,
                    canvasSize: canvasSize,
                    totalValue: totalValue,
                    regionChannels:
                        channelsByRegion[_selectedNode!.regionCode] ?? 0,
                    regionIndex: widget.regionIndex,
                    onClose: () => setState(() {
                      _selectedNode = null;
                      _selectedOffset = null;
                    }),
                  ),
              ],
            ),
          );
        }),

        // ── Stats bar ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(
              GwpSpacing.base, GwpSpacing.sm, GwpSpacing.base, GwpSpacing.md),
          decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: GwpColors.border, width: 0.5)),
          ),
          child: LayoutBuilder(
            builder: (context, bc) {
              // 窄屏（< 300dp）隐藏右侧 badge，避免溢出
              final narrow = bc.maxWidth < 300;
              return Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _MapStat(
                      key: ValueKey(regionCount),
                      icon: Icons.language_rounded,
                      value: '$regionCount',
                      label: widget.scope == _MapScope.country ? '个地区' : '个区域',
                    ),
                  ),
                  const SizedBox(width: GwpSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _MapStat(
                      key: ValueKey(accountCount),
                      icon: Icons.account_balance_rounded,
                      value: '$accountCount',
                      label: '个账户',
                    ),
                  ),
                  if (channelCount > 0) ...[
                    const SizedBox(width: GwpSpacing.md),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _MapStat(
                        key: ValueKey(channelCount),
                        icon: Icons.swap_horiz_rounded,
                        value: '$channelCount',
                        label: '条通道',
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (topNode != null && !narrow) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              GwpColors.actionPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: GwpColors.actionPrimary
                                  .withValues(alpha: 0.25),
                              width: 0.5),
                        ),
                        child: Text(
                          '主导 ${regionLabel(widget.regionIndex, topNode.regionCode)} · ${topPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            color: GwpColors.actionPrimary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Text(
                    'GLOBAL',
                    style: TextStyle(
                      color: GwpColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Filter bottom sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialPresetIdx,
    required this.initialLayers,
    required this.initialContinents,
    required this.availableContinents,
    required this.initialScope,
    required this.onChanged,
  });

  final int initialPresetIdx;
  final Set<_MapLayer> initialLayers;
  final Set<String> initialContinents;
  final Set<String> availableContinents;
  final _MapScope initialScope;
  final void Function(
    int presetIdx,
    Set<_MapLayer> layers,
    Set<String> continents,
    _MapScope scope,
  ) onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _presetIdx;
  late Set<_MapLayer> _layers;
  late Set<String> _continents;
  late _MapScope _scope;

  @override
  void initState() {
    super.initState();
    _presetIdx = widget.initialPresetIdx;
    _layers = Set.from(widget.initialLayers);
    _continents = Set.from(widget.initialContinents);
    _scope = widget.initialScope;
  }

  void _selectPreset(int idx) {
    setState(() {
      _presetIdx = idx;
      _layers = Set.from(_kPresets[idx].layers);
    });
    _notify();
  }

  void _toggleLayer(_MapLayer layer) {
    setState(() {
      _presetIdx = -1;
      if (_layers.contains(layer)) {
        _layers.remove(layer);
      } else {
        _layers.add(layer);
      }
    });
    _notify();
  }

  void _toggleContinent(String cont) {
    setState(() {
      if (_continents.contains(cont)) {
        if (_continents.length > 1) _continents.remove(cont);
      } else {
        _continents.add(cont);
      }
    });
    _notify();
  }

  void _notify() =>
      widget.onChanged(_presetIdx, _layers, _continents, _scope);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GwpSpacing.base,
        GwpSpacing.base,
        GwpSpacing.base,
        GwpSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: GwpColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: GwpSpacing.base),

          // Title + reset
          Row(
            children: [
              const Text(
                '地图过滤',
                style: TextStyle(
                  color: GwpColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _presetIdx = _kDefaultPresetIdx;
                    _layers = Set.from(_kPresets[_kDefaultPresetIdx].layers);
                    _continents = Set.from(widget.availableContinents);
                    _scope = widget.initialScope;
                  });
                  _notify();
                },
                child: const Text(
                  '重置',
                  style: TextStyle(
                    color: GwpColors.actionPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.base),

          const Text(
            '地图粒度',
            style: TextStyle(
                color: GwpColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: GwpSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final option in _MapScope.values)
                GestureDetector(
                  onTap: () {
                    setState(() => _scope = option);
                    _notify();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _scope == option
                          ? GwpColors.actionPrimary.withValues(alpha: 0.15)
                          : GwpColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _scope == option
                            ? GwpColors.actionPrimary
                            : GwpColors.border,
                        width: _scope == option ? 1.0 : 0.5,
                      ),
                    ),
                    child: Text(
                      option == _MapScope.country ? '国家视图' : '区域视图',
                      style: TextStyle(
                        color: _scope == option
                            ? GwpColors.actionPrimary
                            : GwpColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            _scope == option ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GwpSpacing.base),

          // ── Presets ────────────────────────────────────────
          const Text(
            '预设方案',
            style: TextStyle(
                color: GwpColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: GwpSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(_kPresets.length, (i) {
              final selected = _presetIdx == i;
              return GestureDetector(
                onTap: () => _selectPreset(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? GwpColors.actionPrimary.withValues(alpha: 0.15)
                        : GwpColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? GwpColors.actionPrimary
                          : GwpColors.border,
                      width: selected ? 1.0 : 0.5,
                    ),
                  ),
                  child: Text(
                    _kPresets[i].label,
                    style: TextStyle(
                      color: selected
                          ? GwpColors.actionPrimary
                          : GwpColors.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: GwpSpacing.base),

          // ── Layer toggles ──────────────────────────────────
          const Text(
            '显示图层',
            style: TextStyle(
                color: GwpColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          _LayerToggleRow(
            label: '地区节点',
            sublabel: '资产节点圆圈',
            icon: Icons.radio_button_checked_rounded,
            value: _layers.contains(_MapLayer.regionDots),
            onToggle: () => _toggleLayer(_MapLayer.regionDots),
          ),
          _LayerToggleRow(
            label: '通道连线',
            sublabel: '跨地区资金通道',
            icon: Icons.swap_horiz_rounded,
            value: _layers.contains(_MapLayer.edges),
            onToggle: () => _toggleLayer(_MapLayer.edges),
          ),
          _LayerToggleRow(
            label: '地区标签',
            sublabel: '节点旁代码标注',
            icon: Icons.label_outline_rounded,
            value: _layers.contains(_MapLayer.labels),
            onToggle: () => _toggleLayer(_MapLayer.labels),
          ),
          _LayerToggleRow(
            label: '热区光晕',
            sublabel: '有资产的陆地高亮',
            icon: Icons.blur_on_rounded,
            value: _layers.contains(_MapLayer.glow),
            onToggle: () => _toggleLayer(_MapLayer.glow),
          ),

          // ── Continent scope (only if >1 continent in data) ─
          if (widget.availableContinents.length > 1) ...[
            const SizedBox(height: GwpSpacing.base),
            const Text(
              '地区范围',
              style: TextStyle(
                  color: GwpColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: GwpSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: orderedContinentLabels(widget.availableContinents)
                  .map((cont) {
                final active = _continents.contains(cont);
                final cColor =
                    kContinentColors[cont] ?? GwpColors.actionPrimary;
                return GestureDetector(
                  onTap: () => _toggleContinent(cont),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? cColor.withValues(alpha: 0.12)
                          : GwpColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? cColor : GwpColors.border,
                        width: active ? 1.0 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: cColor,
                            ),
                          ),
                        Text(
                          cont,
                          style: TextStyle(
                            color:
                                active ? cColor : GwpColors.textSecondary,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: GwpSpacing.sm),
        ],
      ),
    );
  }
}

class _LayerToggleRow extends StatelessWidget {
  const _LayerToggleRow({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.value,
    required this.onToggle,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 16, color: GwpColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: GwpColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      color: GwpColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: GwpColors.actionPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Node info popup  (animated entrance)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _NodeInfoPopup extends StatefulWidget {
  const _NodeInfoPopup({
    super.key,
    required this.node,
    required this.dotOffset,
    required this.canvasSize,
    required this.totalValue,
    required this.regionChannels,
    required this.regionIndex,
    required this.onClose,
  });

  final MapNode node;
  final Offset dotOffset;
  final Size canvasSize;
  final double totalValue;
  final int regionChannels;
  final RegionIndex regionIndex;
  final VoidCallback onClose;

  @override
  State<_NodeInfoPopup> createState() => _NodeInfoPopupState();
}

class _NodeInfoPopupState extends State<_NodeInfoPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const popupWidth = 162.0;
    const popupHeight = 116.0;
    const arrowGap = 10.0;
    const margin = 8.0;

    final node = widget.node;
    final showAbove = widget.dotOffset.dy > widget.canvasSize.height * 0.45;

    double left = widget.dotOffset.dx - popupWidth / 2;
    left = left.clamp(margin, widget.canvasSize.width - popupWidth - margin);

    var top = showAbove
        ? widget.dotOffset.dy - popupHeight - arrowGap
        : widget.dotOffset.dy + arrowGap;
    top = top.clamp(margin, widget.canvasSize.height - popupHeight - margin);

    final pct = widget.totalValue > 0 ? (node.value / widget.totalValue) : 0.0;
    final pctStr =
        widget.totalValue > 0 ? '${(pct * 100).toStringAsFixed(2)}%' : '—';

    final continent = regionMetaOf(widget.regionIndex, node.regionCode)?.continent;
    final accentColor =
        kContinentColors[continent] ?? GwpColors.actionPrimary;
    final regionName = regionMetaOf(widget.regionIndex, node.regionCode)?.shortName
        ?? regionLabel(widget.regionIndex, node.regionCode);
    final scaleAlign =
        showAbove ? Alignment.bottomCenter : Alignment.topCenter;

    return Positioned(
      left: left,
      top: top,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: scaleAlign,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: popupWidth,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: BoxDecoration(
                color: GwpColors.surface2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.45), width: 0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header row ──────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        node.regionCode,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          regionName,
                          style: const TextStyle(
                            color: GwpColors.textMuted,
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onClose();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: GwpColors.textMuted
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Value ───────────────────────────────────
                  Text(
                    node.label,
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      color: GwpColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  // ── Portfolio bar ────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(height: 3, color: GwpColors.border),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  // ── Footer: pct badge + accounts + channels ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          pctStr,
                          style: TextStyle(
                            fontFamily: GwpTypo.monoFont,
                            color: accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(Icons.account_balance_rounded,
                          size: 10, color: GwpColors.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        '${node.accountCount}',
                        style: const TextStyle(
                            color: GwpColors.textMuted, fontSize: 10),
                      ),
                      if (widget.regionChannels > 0) ...[
                        const SizedBox(width: 7),
                        Icon(Icons.swap_horiz_rounded,
                            size: 10, color: GwpColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.regionChannels}',
                          style: const TextStyle(
                              color: GwpColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stats pill widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _MapStat extends StatelessWidget {
  const _MapStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: GwpColors.actionPrimary),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: GwpTypo.monoFont,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GwpColors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: GwpColors.textMuted),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Dot-matrix world map painter
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DotWorldPainter extends CustomPainter {
  const _DotWorldPainter({
    required this.nodes,
    required this.edges,
    required this.layers,
    required this.forcedCells,
    required this.activeProjected,
    required this.regionIndex,
    this.selectedRegion,
    this.pulseValue = 0.0,
  });

  final List<MapNode> nodes;
  final List<MapEdge> edges;
  final Set<_MapLayer> layers;
  /// Land cells that must be lit regardless of the polygon bitmap (one per node).
  final Set<(int, int)> forcedCells;
  /// Projected-space normalised (x, y) coords for nodes used by the glow test;
  /// pre-computed in build() so paint() doesn't recompute per frame.
  final List<(double, double)> activeProjected;
  final RegionIndex regionIndex;
  final String? selectedRegion;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    _drawDotMatrix(canvas, size);
    if (layers.contains(_MapLayer.edges)) _drawEdges(canvas, size);
    if (layers.contains(_MapLayer.regionDots)) {
      _drawRegionDots(canvas, size);
      _drawRankBadges(canvas, size);
      if (layers.contains(_MapLayer.labels)) {
        _drawRegionLabels(canvas, size);
      }
    }
    _drawVignette(canvas, size);
  }

  // ── Dot matrix ───────────────────────────────────────────────
  void _drawDotMatrix(Canvas canvas, Size size) {
    final spacingX = size.width / _dotCols;
    final dotR = (spacingX * 0.27).clamp(0.75, 1.55);

    final showGlow = layers.contains(_MapLayer.glow);

    final bitmap = _landSurface.bitmap;
    for (var r = 0; r < _dotRows; r++) {
      for (var c = 0; c < _dotCols; c++) {
        final isLand = bitmap[r][c] || forcedCells.contains((c, r));
        if (!isLand) continue;

        final nx = (c + 0.5) / _dotCols;
        final ny = (r + 0.5) / _dotRows;
        final center = Offset(nx * size.width, ny * size.height);
        final edgeFactor = (1 - (nx - 0.5).abs() * 1.15).clamp(0.45, 1.0);

        var isHot = false;
        if (showGlow) {
          for (final ac in activeProjected) {
            final dx = nx - ac.$1, dy = ny - ac.$2;
            if (dx * dx + dy * dy < 0.0052) {
              isHot = true;
              break;
            }
          }
        }

        final landPaint = Paint()
          ..color = GwpColors.borderStrong
              .withValues(alpha: 0.22 + edgeFactor * 0.24)
          ..style = PaintingStyle.fill;
        final activePaint = Paint()
          ..color = GwpColors.actionPrimary
              .withValues(alpha: 0.18 + edgeFactor * 0.26)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          center,
          dotR * (0.92 + edgeFactor * 0.12),
          isHot ? activePaint : landPaint,
        );
      }
    }

    _drawGuideLine(
      canvas,
      size,
      yNorm: 0.50,
      color: GwpColors.border.withValues(alpha: 0.22),
      strokeWidth: 0.5,
    );
    _drawGuideLine(
      canvas,
      size,
      yNorm: 0.333,
      color: GwpColors.border.withValues(alpha: 0.10),
      strokeWidth: 0.4,
    );
    _drawGuideLine(
      canvas,
      size,
      yNorm: 0.667,
      color: GwpColors.border.withValues(alpha: 0.10),
      strokeWidth: 0.4,
    );
  }

  void _drawGuideLine(
    Canvas canvas,
    Size size, {
    required double yNorm,
    required Color color,
    required double strokeWidth,
  }) {
    final points = heroProjectGuide(size, yNorm);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  // ── Edges ────────────────────────────────────────────────────
  void _drawEdges(Canvas canvas, Size size) {
    final compact = size.width < 430;
    for (final edge in edges) {
      final geometry = projectEdgeGeometry(
        size: size,
        fromCoords: regionMetaOf(regionIndex, edge.fromRegion)?.mapCoords,
        toCoords: regionMetaOf(regionIndex, edge.toRegion)?.mapCoords,
        arcLiftFactor: 0.20,
        arcDepthFactor: 0.08,
        heightLiftFactor: 0.025,
        heightDepthFactor: 0.018,
      );
      if (geometry == null) continue;

      final depth = geometry.depth;
      final sw = geometry.recommendedStrokeWidth(
        count: edge.channelCount,
        base: 0.65,
        countFactor: 0.22,
        depthBase: 0.82,
        depthFactor: 0.36,
        min: 0.65,
        max: 2.35,
      );
      final path = geometry.buildPath();

      canvas.drawPath(
        path,
        Paint()
          ..color = GwpColors.actionPrimary.withValues(
              alpha: (compact ? 0.08 : 0.10) + depth * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw + (compact ? 1.0 : 1.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, compact ? 2.2 : 3.0),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = GwpColors.actionPrimary.withValues(alpha: 0.28 + depth * 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw,
      );

      final termPaint = Paint()
        ..color = GwpColors.actionPrimary.withValues(alpha: 0.35 + depth * 0.28)
        ..style = PaintingStyle.fill;
      final terminalRadius = geometry.recommendedTerminalRadius(
        strokeWidth: sw,
        base: 0.75,
        depthFactor: 0.2,
      );
      canvas.drawCircle(geometry.from, terminalRadius, termPaint);
      canvas.drawCircle(geometry.to, terminalRadius, termPaint);
    }
  }

  // ── Region dots ──────────────────────────────────────────────
  void _drawRegionDots(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final compact = size.width < 430;
    final maxVal = nodes.fold<double>(0, (m, n) => n.value > m ? n.value : m);

    for (final node in nodes) {
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;
      final center = FinanceMapProjection.projectPoint(size, coords);
      final depth = FinanceMapProjection.projectDepth(coords);

      final ratio =
          maxVal > 0 ? (node.value / maxVal).clamp(0.0, 1.0) : 0.5;
      final isSel = node.regionCode == selectedRegion;

      final continent = regionMetaOf(regionIndex, node.regionCode)?.continent;
      final nodeColor =
          kContinentColors[continent] ?? GwpColors.actionPrimary;

      // Radar-ping ring (expanding + fading)
      // Phase-offset each node slightly so they don't all pulse together
      final phaseOffset = ((coords.$1 + coords.$2) * 3.7) % 1.0;
      final phase = (pulseValue + phaseOffset) % 1.0;
      final pingR = ((isSel ? 7.2 : 4.8) + phase * 8.8) * (0.90 + depth * 0.18);
      final pingAlpha = (1 - phase) * (isSel ? 0.22 : 0.10) * (0.72 + depth * 0.28);
      if (pingAlpha > 0.005) {
        canvas.drawCircle(
          center,
          pingR,
          Paint()
            ..color = nodeColor.withValues(alpha: pingAlpha)
            ..style = PaintingStyle.fill,
        );
      }

      for (var ring = 3; ring >= 1; ring--) {
        canvas.drawCircle(
          center,
          ((isSel ? 5.8 : 3.8) + ring * 3.0) *
              (0.88 + depth * 0.16) *
              (compact ? 0.92 : 1.0),
          Paint()
            ..color = nodeColor.withValues(
                alpha: (isSel ? 0.11 * ring : 0.045 * ring) * (0.72 + depth * 0.28))
            ..style = PaintingStyle.fill,
        );
      }

      final dotR = (1.55 + ratio * 1.65) * (0.84 + depth * 0.20) * (compact ? 0.90 : 1.0);
      canvas.drawCircle(
        center,
        dotR,
        Paint()
          ..color = isSel
              ? GwpColors.textPrimary.withValues(alpha: 0.96)
              : nodeColor.withValues(alpha: 0.78 + depth * 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        dotR,
        Paint()
          ..color = GwpColors.textPrimary
              .withValues(alpha: isSel ? 0.60 + depth * 0.12 : 0.18 + depth * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 1.0 : 0.65,
      );
    }
  }

  // ── TOP-3 rank badges ────────────────────────────────────────
  void _drawRankBadges(Canvas canvas, Size size) {
    final badgeRects = _topBadgeRects(size);
    for (final entry in badgeRects.entries) {
      final rank = entry.key;
      final badge = entry.value;
      canvas.drawCircle(
          badge.center,
          badge.radius,
          Paint()..color = badge.color.withValues(alpha: 0.78 + badge.depth * 0.12));
      canvas.drawCircle(
          badge.center,
          badge.radius,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.16 + badge.depth * 0.06)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);

      final tp = TextPainter(
        text: TextSpan(
          text: '$rank',
          style: const TextStyle(
            fontSize: 6.0,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(badge.center.dx - tp.width / 2, badge.center.dy - tp.height / 2),
      );
    }
  }

  Map<int, _HeroBadgeLayout> _topBadgeRects(Size size) {
    if (nodes.isEmpty) return <int, _HeroBadgeLayout>{};
    final sorted = [...nodes]..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final result = <int, _HeroBadgeLayout>{};

    for (var i = 0; i < top.length; i++) {
      final node = top[i];
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;

      final projected = heroProjectPoint(size, coords);
      final depth = heroProjectDepth(coords);
      final continent = regionMetaOf(regionIndex, node.regionCode)?.continent;
      final badgeColor =
          kContinentColors[continent] ?? GwpColors.actionPrimary;
      final badgeR = 4.4 + depth * 0.75;
      final center = Offset(projected.dx - badgeR, projected.dy - badgeR);
      result[i + 1] = _HeroBadgeLayout(
        center: center,
        radius: badgeR,
        color: badgeColor,
        depth: depth,
      );
    }

    return result;
  }

  // ── Region code labels ───────────────────────────────────────
  void _drawRegionLabels(Canvas canvas, Size size) {
    final sorted = [...nodes]..sort((a, b) => b.value.compareTo(a.value));
    final priorityByCode = <String, int>{
      for (var i = 0; i < sorted.length; i++) sorted[i].regionCode: sorted.length - i,
    };
    final topCodes = sorted.take(3).map((n) => n.regionCode).toSet();
    final reservedRects = _topBadgeRects(size)
        .values
        .map((badge) => Rect.fromCircle(center: badge.center, radius: badge.radius + 1))
        .toList();
    final specs = <ProjectedLabelSpec>[];
    final textPainters = <String, TextPainter>{};
    final depths = <String, double>{};
    final centers = <String, Offset>{};
    final colors = <String, Color>{};

    for (final node in nodes) {
      if (node.regionCode == selectedRegion) continue;
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;

      final projected = heroProjectPoint(size, coords);
      final depth = heroProjectDepth(coords);
      final continent = regionMetaOf(regionIndex, node.regionCode)?.continent;
      final labelColor =
          (kContinentColors[continent] ?? GwpColors.textMuted)
              .withValues(alpha: 0.34 + depth * 0.26);
      final tp = TextPainter(
        text: TextSpan(
          text: node.regionCode,
          style: TextStyle(
            fontSize: 6.5,
            color: labelColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 24);

      textPainters[node.regionCode] = tp;
      depths[node.regionCode] = depth;
      centers[node.regionCode] = projected;
      colors[node.regionCode] = labelColor;
      specs.add(
        ProjectedLabelSpec(
          id: node.regionCode,
          center: projected,
          size: tp.size,
          anchorRadius: 3.5,
          priority: (priorityByCode[node.regionCode] ?? 0) * 100 + node.accountCount,
          keepVisible: topCodes.contains(node.regionCode),
          gap: 2,
          maxRing: 3,
          ringSpacing: 8,
        ),
      );
    }

    final placements = computeProjectedLabelPlacements(
      size,
      specs,
      reservedRects: reservedRects,
      padding: 2,
    );

    for (final placement in placements) {
      if (!placement.visible) continue;
      final tp = textPainters[placement.id];
      final center = centers[placement.id];
      final color = colors[placement.id];
      if (tp == null || center == null || color == null) continue;

      if (placement.showLeaderLine) {
        canvas.drawLine(
          center,
          placement.attachPoint,
          Paint()
            ..color = color.withValues(alpha: 0.32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }

      tp.paint(canvas, placement.rect.topLeft);
    }
  }

  // ── Edge vignette ─────────────────────────────────────────────
  void _drawVignette(Canvas canvas, Size size) {
    final focusRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.18),
      width: size.width * 0.92,
      height: size.height * 0.54,
    );
    canvas.drawOval(
      focusRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            GwpColors.actionPrimary.withValues(alpha: 0.14),
            const Color(0x00141414),
          ],
          stops: const [0.0, 1.0],
        ).createShader(focusRect),
    );

    const bg = GwpColors.surface1;
    const bgT = Color(0x00141414);
    final sw = size.width * 0.04;
    final sh = size.height * 0.18;

    final lR = Rect.fromLTWH(0, 0, sw, size.height);
    canvas.drawRect(lR,
        Paint()..shader = const LinearGradient(colors: [bg, bgT]).createShader(lR));

    final rR = Rect.fromLTWH(size.width - sw, 0, sw, size.height);
    canvas.drawRect(rR,
        Paint()..shader = const LinearGradient(colors: [bgT, bg]).createShader(rR));

    final tR = Rect.fromLTWH(0, 0, size.width, sh);
    canvas.drawRect(
        tR,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bg, bgT],
          ).createShader(tR));

    final bR = Rect.fromLTWH(0, size.height - sh * 1.2, size.width, sh * 1.2);
    canvas.drawRect(
        bR,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgT,
              bg.withValues(alpha: 0.92),
            ],
          ).createShader(bR));
  }

  @override
  bool shouldRepaint(_DotWorldPainter old) =>
      old.nodes != nodes ||
      old.edges != edges ||
      old.layers != layers ||
      old.selectedRegion != selectedRegion ||
      old.pulseValue != pulseValue;
}

class _HeroBadgeLayout {
  const _HeroBadgeLayout({
    required this.center,
    required this.radius,
    required this.color,
    required this.depth,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double depth;
}
