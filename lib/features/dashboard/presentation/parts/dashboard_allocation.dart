part of '../dashboard_page.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// C. Asset Allocation — segmented control + single big donut
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum _AllocMode { currency, type, region }

const _typeColors = [
  Color(0xFF64748B),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFFF97316),
  Color(0xFF14B8A6),
  Color(0xFF6366F1),
];

const _currencyColors = <String, Color>{
  'CNY': Color(0xFFE53935),
  'USD': Color(0xFF43A047),
  'EUR': Color(0xFF1E88E5),
  'JPY': Color(0xFFFB8C00),
  'GBP': Color(0xFF8E24AA),
  'HKD': Color(0xFFD81B60),
  'SGD': Color(0xFF00ACC1),
};

class _AllocationSection extends ConsumerStatefulWidget {
  const _AllocationSection();
  @override
  ConsumerState<_AllocationSection> createState() =>
      _AllocationSectionState();
}

class _AllocationSectionState extends ConsumerState<_AllocationSection> {
  _AllocMode _mode = _AllocMode.currency;

  FutureProvider<List<AllocationSlice>> get _provider => switch (_mode) {
        _AllocMode.currency => allocationByCurrencyProvider,
        _AllocMode.type => allocationByTypeProvider,
        _AllocMode.region => allocationByRegionAggregateProvider,
      };

  Color _colorOf(String key, int idx) => switch (_mode) {
        _AllocMode.currency =>
          _currencyColors[key] ?? _typeColors[idx % _typeColors.length],
        _AllocMode.type => _typeColors[idx % _typeColors.length],
        _AllocMode.region => regionColor(
            ref.watch(regionMetaIndexProvider).value ?? const {}, key),
      };

  String get _centerUnit => switch (_mode) {
        _AllocMode.currency => '种货币',
        _AllocMode.type => '种类型',
        _AllocMode.region => '个地区',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(_provider);
    return Container(
      padding: const EdgeInsets.all(CofferSpacing.sm),
      decoration: BoxDecoration(
        color: CofferColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CofferColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _AllocTabs(
            current: _mode,
            onPick: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: CofferSpacing.sm),
          dataAsync.when(
            loading: () => const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                  color: CofferColors.actionPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox(
              height: 140,
              child: Center(
                child: Icon(Icons.error_outline, color: CofferColors.textMuted),
              ),
            ),
            data: (slices) {
              if (slices.isEmpty) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Text('暂无数据',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CofferColors.textMuted,
                        )),
                  ),
                );
              }
              final total = slices.fold<double>(0, (a, s) => a + s.value);
              final segments = <ChartSegment>[
                for (var i = 0; i < slices.length; i++)
                  ChartSegment(
                    label: slices[i].key,
                    value: slices[i].value,
                    color: _colorOf(slices[i].key, i),
                  ),
              ];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CofferDonutChart(
                    segments: segments,
                    centerLabel: '${slices.length}',
                    centerSubLabel: _centerUnit,
                    size: 110,
                    strokeWidth: 18,
                  ),
                  const SizedBox(width: CofferSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < slices.length && i < 5; i++)
                          _AllocLegendRow(
                            label: slices[i].key,
                            color: _colorOf(slices[i].key, i),
                            pct: total > 0 ? slices[i].value / total : 0,
                          ),
                        if (slices.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '等 ${slices.length} 项',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: CofferColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AllocTabs extends StatelessWidget {
  const _AllocTabs({required this.current, required this.onPick});
  final _AllocMode current;
  final ValueChanged<_AllocMode> onPick;

  static const _labels = {
    _AllocMode.currency: '按币种',
    _AllocMode.type: '按类型',
    _AllocMode.region: '按地区',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CofferColors.surface3,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final m in _AllocMode.values)
            Expanded(
              child: InkWell(
                onTap: () => onPick(m),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: current == m
                        ? CofferColors.actionPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _labels[m]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: current == m
                          ? Colors.white
                          : CofferColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllocLegendRow extends StatelessWidget {
  const _AllocLegendRow({
    required this.label,
    required this.color,
    required this.pct,
  });
  final String label;
  final Color color;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CofferColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${(pct * 100).toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: CofferTypo.monoFont,
              color: CofferColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
