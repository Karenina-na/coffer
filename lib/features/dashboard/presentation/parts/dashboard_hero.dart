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

// ── Continent polygons — equirectangular (x, y) ───────────────
// All coordinates: x=(lon+180)/360, y=(90-lat)/180

const _continentPolygons = <List<(double, double)>>[
  // ── North America ─────────────────────────────────────────
  [
    (0.033, 0.133), // Alaska W   -168° 66°N
    (0.264, 0.094), // N Canada    -85° 73°N
    (0.353, 0.239), // Newfoundland -53° 47°N
    (0.314, 0.256), // Nova Scotia  -67° 44°N
    (0.292, 0.306), // Cape Hatteras-75° 35°N
    (0.278, 0.361), // Florida tip  -80° 25°N
    (0.256, 0.406), // Yucatan      -88° 17°N
    (0.283, 0.456), // Panama       -79°  8°N
    (0.208, 0.394), // Mexico W    -105° 19°N
    (0.175, 0.322), // Baja S      -117° 32°N
    (0.156, 0.228), // Oregon      -124° 49°N
    (0.119, 0.172), // Alaska S    -137° 59°N
    (0.069, 0.178), // Alaska SW   -155° 58°N
    (0.033, 0.167), // Alaska W    -168° 60°N
  ],
  // ── South America ─────────────────────────────────────────
  [
    (0.283, 0.444), // Colombia W   -78° 10°N
    (0.333, 0.444), // Venezuela    -60° 10°N
    (0.361, 0.478), // Guyana       -50°  4°N
    (0.400, 0.539), // Brazil NE    -36° -6°S
    (0.403, 0.561), // Brazil E     -35°-11°S
    (0.392, 0.622), // Brazil SE    -39°-22°S
    (0.361, 0.678), // Uruguay      -50°-32°S
    (0.317, 0.806), // Tierra del Fuego -66°-55°S
    (0.294, 0.778), // Chile tip    -74°-50°S
    (0.300, 0.611), // Chile mid    -72°-20°S
    (0.272, 0.517), // Ecuador W    -82° -3°S
  ],
  // ── Europe (mainland) ─────────────────────────────────────
  [
    (0.475, 0.300), // Portugal      -9° 36°N
    (0.500, 0.261), // S France       0° 43°N
    (0.542, 0.294), // S Italy       15° 37°N
    (0.578, 0.272), // Greece        28° 41°N
    (0.617, 0.261), // Caucasus/Turkey E  42° 43°N
    (0.622, 0.222), // Ukraine E     44° 50°N
    (0.583, 0.167), // Russia NW     30° 60°N
    (0.578, 0.106), // N Norway/Russia 28° 71°N
    (0.542, 0.111), // N Norway      15° 70°N
    (0.514, 0.178), // Norway SW      5° 58°N
    (0.522, 0.189), // Jutland        8° 56°N
    (0.528, 0.200), // N Germany     10° 54°N
    (0.506, 0.217), // Netherlands    2° 51°N
    (0.472, 0.300), // Portugal W   -10° 36°N
  ],
  // ── Africa ────────────────────────────────────────────────
  [
    (0.450, 0.417), // Senegal/Mauritania -18° 15°N
    (0.461, 0.300), // Morocco NW   -14° 36°N
    (0.528, 0.294), // Tunisia       10° 37°N
    (0.569, 0.322), // Libya         25° 32°N
    (0.603, 0.378), // Red Sea       37° 22°N
    (0.642, 0.433), // Horn          51° 12°N
    (0.622, 0.511), // Kenya coast   44° -2°S
    (0.611, 0.639), // Mozambique    40°-25°S
    (0.553, 0.694), // Cape          19°-35°S
    (0.542, 0.661), // S Africa W    15°-29°S
    (0.533, 0.594), // Angola        12°-17°S
    (0.525, 0.522), // Congo/Gabon    9°  -4°S
    (0.506, 0.472), // Gulf of Guinea 2°   5°N
  ],
  // ── Asia (mainland, including Malay Peninsula) ────────────
  [
    (0.575, 0.294), // Turkey W      27° 37°N
    (0.600, 0.300), // Turkey E/Syria 36° 36°N
    (0.639, 0.333), // Persian Gulf  50° 30°N
    (0.678, 0.372), // Pakistan W    64° 23°N
    (0.714, 0.456), // India S tip   77°  8°N
    (0.722, 0.428), // India SE      80° 13°N
    (0.756, 0.378), // Bay of Bengal 92° 22°N
    (0.778, 0.411), // Indochina    100° 16°N
    (0.789, 0.489), // Malay Peninsula 104°  2°N
    (0.803, 0.483), // Malay E coast 108°  3°N
    (0.806, 0.389), // Vietnam N    110° 20°N
    (0.825, 0.367), // SE China     117° 24°N
    (0.839, 0.328), // E China      122° 31°N
    (0.858, 0.306), // Korea        129° 35°N
    (0.864, 0.261), // Manchuria    131° 43°N
    (0.953, 0.200), // Kamchatka    163° 54°N
    (0.997, 0.133), // Chukotka     180° 66°N (clipped)
    (0.889, 0.094), // Siberia NE   140° 73°N
    (0.722, 0.100), // W Siberia     80° 72°N
    (0.661, 0.167), // Ural          58° 60°N
    (0.631, 0.267), // Caucasus      47° 42°N
  ],
  // ── Australia ─────────────────────────────────────────────
  [
    (0.817, 0.678), // W coast     114°-32°S
    (0.819, 0.622), // NW          115°-22°S
    (0.864, 0.567), // N           131°-12°S
    (0.894, 0.556), // NE          142°-10°S
    (0.925, 0.678), // E coast     153°-32°S
    (0.911, 0.717), // SE          148°-39°S
    (0.878, 0.711), // S           136°-38°S
    (0.819, 0.689), // SW          115°-34°S
  ],
  // ── Greenland ─────────────────────────────────────────────
  [
    (0.361, 0.167), // SW  -50° 60°N
    (0.347, 0.111), // W   -55° 70°N
    (0.375, 0.039), // N   -45° 83°N
    (0.444, 0.083), // NE  -20° 75°N
    (0.444, 0.167), // SE  -20° 60°N
  ],
];

// ── Island patches (x1,y1,x2,y2 bounding boxes) ──────────────
// Forces specific cells to be land regardless of polygon tests.

const _islandPatches = <(double, double, double, double)>[
  (0.858, 0.267, 0.903, 0.328), // Japan: Honshu + Kyushu
  (0.892, 0.244, 0.914, 0.267), // Japan: Hokkaido
  (0.481, 0.172, 0.511, 0.222), // UK: Britain
  (0.469, 0.194, 0.483, 0.217), // Ireland
  (0.428, 0.133, 0.464, 0.156), // Iceland
  (0.831, 0.356, 0.842, 0.378), // Taiwan
  (0.825, 0.394, 0.853, 0.456), // Philippines (rough)
  (0.717, 0.444, 0.728, 0.472), // Sri Lanka
  (0.781, 0.489, 0.795, 0.500), // Singapore area
  (0.961, 0.711, 0.994, 0.767), // New Zealand (North+South)
  (0.619, 0.556, 0.636, 0.644), // Madagascar
];

// ── Dot-matrix land bitmap (pre-computed, lazy) ───────────────

const _dotCols = 88;
const _dotRows = 42;

final _landBitmap = _computeLandBitmap();

List<List<bool>> _computeLandBitmap() {
  final bitmap =
      List.generate(_dotRows, (_) => List.filled(_dotCols, false));
  for (var r = 0; r < _dotRows; r++) {
    for (var c = 0; c < _dotCols; c++) {
      final nx = (c + 0.5) / _dotCols;
      final ny = (r + 0.5) / _dotRows;

      // Polygon test
      var isLand = false;
      for (final poly in _continentPolygons) {
        if (_pointInPolygon(nx, ny, poly)) {
          isLand = true;
          break;
        }
      }
      // Island patch test
      if (!isLand) {
        for (final p in _islandPatches) {
          if (nx >= p.$1 && nx <= p.$3 && ny >= p.$2 && ny <= p.$4) {
            isLand = true;
            break;
          }
        }
      }

      bitmap[r][c] = isLand;
    }
  }
  return bitmap;
}

bool _pointInPolygon(
    double px, double py, List<(double, double)> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].$1, yi = polygon[i].$2;
    final xj = polygon[j].$1, yj = polygon[j].$2;
    if ((yi > py) != (yj > py) &&
        px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Hero widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridMapHero extends ConsumerWidget {
  const _GridMapHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(nodeMapDataProvider);
    final regionIndex =
        ref.watch(regionMetaIndexProvider).value ?? const {};

    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: mapAsync.when(
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
        data: (mapData) =>
            _GridMapContent(mapData: mapData, regionIndex: regionIndex),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Map content (stateful: filter + selection)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridMapContent extends StatefulWidget {
  const _GridMapContent({required this.mapData, required this.regionIndex});
  final NodeMapData mapData;
  final RegionIndex regionIndex;

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
      .map((n) => regionMetaOf(widget.regionIndex, n.regionCode)?.continent ?? '其他')
      .toSet();

  void _openFilterSheet() {
    final dataContinents = _dataContinents;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GwpColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        initialPresetIdx: _presetIdx,
        initialLayers: _layers,
        initialContinents: _visibleContinents ?? dataContinents,
        availableContinents: dataContinents,
        onChanged: (idx, layers, continents) {
          setState(() {
            _presetIdx = idx;
            _layers = Set.from(layers);
            // null if all selected
            _visibleContinents =
                continents.length == dataContinents.length
                    ? null
                    : Set.from(continents);
          });
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
        final dotPos = Offset(
            coords.$1 * canvasSize.width, coords.$2 * canvasSize.height);
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
    final activeNorm = <(double, double)>[];
    for (final n in nodes) {
      final c = regionMetaOf(widget.regionIndex, n.regionCode)?.mapCoords;
      if (c == null) continue;
      forcedCells.add((
        (c.$1 * _dotCols).floor().clamp(0, _dotCols - 1),
        (c.$2 * _dotRows).floor().clamp(0, _dotRows - 1),
      ));
      activeNorm.add(c);
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
          const canvasHeight = 180.0;
          final canvasWidth = constraints.maxWidth;
          final canvasSize = Size(canvasWidth, canvasHeight);

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
                        activeNorm: activeNorm,
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
                    '全球持仓分布',
                    style: TextStyle(
                      color: GwpColors.textMuted.withValues(alpha: 0.28),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                // Continent color legend — bottom-left
                if (_layers.contains(_MapLayer.regionDots))
                  Positioned(
                    bottom: 7,
                    left: 10,
                    right: 56, // avoid overlap with filter button
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      children: kContinentList
                          .where((c) => nodes.any((n) =>
                              regionMetaOf(widget.regionIndex, n.regionCode)?.continent == c))
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

                // Tap hint — bottom-right, only when no selection
                if (_selectedNode == null)
                  Positioned(
                    bottom: 7,
                    right: 10,
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

                // Filter button — top-right
                Positioned(
                  top: 8,
                  right: 8,
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
                      label: '个地区',
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
                          '主导 ${topNode.regionCode} · ${topPct.toStringAsFixed(0)}%',
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
    required this.onChanged,
  });

  final int initialPresetIdx;
  final Set<_MapLayer> initialLayers;
  final Set<String> initialContinents;
  final Set<String> availableContinents;
  final void Function(
      int presetIdx, Set<_MapLayer> layers, Set<String> continents) onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _presetIdx;
  late Set<_MapLayer> _layers;
  late Set<String> _continents;

  @override
  void initState() {
    super.initState();
    _presetIdx = widget.initialPresetIdx;
    _layers = Set.from(widget.initialLayers);
    _continents = Set.from(widget.initialContinents);
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
      widget.onChanged(_presetIdx, _layers, _continents);

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
              children: kContinentList
                  .where((c) => widget.availableContinents.contains(c))
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
        widget.totalValue > 0 ? '${(pct * 100).toStringAsFixed(1)}%' : '—';

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
    required this.activeNorm,
    required this.regionIndex,
    this.selectedRegion,
    this.pulseValue = 0.0,
  });

  final List<MapNode> nodes;
  final List<MapEdge> edges;
  final Set<_MapLayer> layers;
  /// Land cells that must be lit regardless of the polygon bitmap (one per node).
  final Set<(int, int)> forcedCells;
  /// Normalised (x, y) coords for nodes used by the glow test; pre-computed
  /// in build() so paint() doesn't recompute per frame.
  final List<(double, double)> activeNorm;
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
    final spacingY = size.height / _dotRows;
    final dotR = (spacingX * 0.27).clamp(0.7, 1.5);

    final landPaint = Paint()
      ..color = GwpColors.borderStrong.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = GwpColors.actionPrimary.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    final showGlow = layers.contains(_MapLayer.glow);

    final bitmap = _landBitmap;
    for (var r = 0; r < _dotRows; r++) {
      for (var c = 0; c < _dotCols; c++) {
        final isLand = bitmap[r][c] || forcedCells.contains((c, r));
        if (!isLand) continue;

        var isHot = false;
        if (showGlow) {
          final nx = (c + 0.5) / _dotCols;
          final ny = (r + 0.5) / _dotRows;
          for (final ac in activeNorm) {
            final dx = nx - ac.$1, dy = ny - ac.$2;
            if (dx * dx + dy * dy < 0.0052) {
              isHot = true;
              break;
            }
          }
        }

        canvas.drawCircle(
          Offset((c + 0.5) * spacingX, (r + 0.5) * spacingY),
          dotR,
          isHot ? activePaint : landPaint,
        );
      }
    }

    // Equator line (main reference)
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      Paint()
        ..color = GwpColors.border.withValues(alpha: 0.22)
        ..strokeWidth = 0.5,
    );

    // Tropic of Cancer ~30°N  y=(90-30)/180=0.333
    // Tropic of Capricorn ~30°S  y=(90+30)/180=0.667
    final tropicPaint = Paint()
      ..color = GwpColors.border.withValues(alpha: 0.10)
      ..strokeWidth = 0.4;
    canvas.drawLine(
        Offset(0, size.height * 0.333),
        Offset(size.width, size.height * 0.333),
        tropicPaint);
    canvas.drawLine(
        Offset(0, size.height * 0.667),
        Offset(size.width, size.height * 0.667),
        tropicPaint);
  }

  // ── Edges ────────────────────────────────────────────────────
  void _drawEdges(Canvas canvas, Size size) {
    for (final edge in edges) {
      final from = regionMetaOf(regionIndex, edge.fromRegion)?.mapCoords;
      final to = regionMetaOf(regionIndex, edge.toRegion)?.mapCoords;
      if (from == null || to == null) continue;

      final p1 = Offset(from.$1 * size.width, from.$2 * size.height);
      final p2 = Offset(to.$1 * size.width, to.$2 * size.height);
      final sw = (0.7 + edge.channelCount * 0.25).clamp(0.7, 2.2);

      final mid = (p1 + p2) / 2;
      final dist = (p1 - p2).distance;
      final control = Offset(mid.dx, mid.dy - dist * 0.20);

      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy),
        Paint()
          ..color = GwpColors.actionPrimary.withValues(alpha: 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw,
      );

      final termPaint = Paint()
        ..color = GwpColors.actionPrimary.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p1, sw * 0.9, termPaint);
      canvas.drawCircle(p2, sw * 0.9, termPaint);
    }
  }

  // ── Region dots ──────────────────────────────────────────────
  void _drawRegionDots(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final maxVal = nodes.fold<double>(0, (m, n) => n.value > m ? n.value : m);

    for (final node in nodes) {
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;
      final center =
          Offset(coords.$1 * size.width, coords.$2 * size.height);

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
      final pingR = (isSel ? 8.0 : 5.5) + phase * 9.0;
      final pingAlpha = (1 - phase) * (isSel ? 0.20 : 0.11);
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
          (isSel ? 6.0 : 4.0) + ring * 3.2,
          Paint()
            ..color = nodeColor
                .withValues(alpha: isSel ? 0.10 * ring : 0.048 * ring)
            ..style = PaintingStyle.fill,
        );
      }

      final dotR = 1.8 + ratio * 1.7;
      canvas.drawCircle(
        center,
        dotR,
        Paint()
          ..color = isSel
              ? GwpColors.textPrimary.withValues(alpha: 0.96)
              : nodeColor.withValues(alpha: 0.90)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        dotR,
        Paint()
          ..color =
              GwpColors.textPrimary.withValues(alpha: isSel ? 0.60 : 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 1.0 : 0.65,
      );
    }
  }

  // ── TOP-3 rank badges ────────────────────────────────────────
  void _drawRankBadges(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final sorted = [...nodes]..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    for (var i = 0; i < top.length; i++) {
      final node = top[i];
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;

      final cx = coords.$1 * size.width;
      final cy = coords.$2 * size.height;
      final continent = regionMetaOf(regionIndex, node.regionCode)?.continent;
      final badgeColor =
          kContinentColors[continent] ?? GwpColors.actionPrimary;

      final bc = Offset(cx - 6.0, cy - 6.0);
      canvas.drawCircle(
          bc, 5.2, Paint()..color = badgeColor.withValues(alpha: 0.88));
      canvas.drawCircle(
          bc,
          5.2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);

      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 6.0,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(bc.dx - tp.width / 2, bc.dy - tp.height / 2));
    }
  }

  // ── Region code labels ───────────────────────────────────────
  void _drawRegionLabels(Canvas canvas, Size size) {
    for (final node in nodes) {
      if (node.regionCode == selectedRegion) continue;
      final coords = regionMetaOf(regionIndex, node.regionCode)?.mapCoords;
      if (coords == null) continue;

      final cx = coords.$1 * size.width;
      final cy = coords.$2 * size.height;

      final continent = regionMetaOf(regionIndex, node.regionCode)?.continent;
      final labelColor =
          (kContinentColors[continent] ?? GwpColors.textMuted)
              .withValues(alpha: 0.52);

      final tp = TextPainter(
        text: TextSpan(
          text: node.regionCode,
          style: TextStyle(
            fontSize: 7.0,
            color: labelColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 28);

      const dotR = 3.5;
      var lx = cx + dotR + 1.5;
      var ly = cy + dotR;
      if (lx + tp.width > size.width - 2) lx = cx - tp.width - dotR - 1.5;
      if (ly + tp.height > size.height - 2) ly = cy - tp.height - dotR;

      tp.paint(canvas, Offset(lx, ly));
    }
  }

  // ── Edge vignette ─────────────────────────────────────────────
  void _drawVignette(Canvas canvas, Size size) {
    const bg = GwpColors.surface1;
    const bgT = Color(0x00141414);
    final sw = size.width * 0.07;
    final sh = size.height * 0.16;

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

    final bR = Rect.fromLTWH(0, size.height - sh, size.width, sh);
    canvas.drawRect(
        bR,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgT, bg],
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
