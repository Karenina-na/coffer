import 'package:flutter/material.dart';

/// A single togglable filter chip backed by a predicate.
class SearchFilterChipSpec<T> {
  const SearchFilterChipSpec({required this.label, required this.predicate});

  final String label;
  final bool Function(T item) predicate;
}

/// A group of filter chips under one category (e.g. "类型" / "状态").
/// Items must satisfy at least one active chip **within each group that has
/// an active chip** (groups are combined with AND; chips within a group are
/// combined with OR).
class SearchFilterGroup<T> {
  const SearchFilterGroup({required this.title, required this.chips});

  final String title;
  final List<SearchFilterChipSpec<T>> chips;
}

/// Compact filter-chip bar used inside the global search delegate's
/// per-feature section.
class SearchFilterChipsBar<T> extends StatelessWidget {
  const SearchFilterChipsBar({
    super.key,
    required this.groups,
    required this.active,
    required this.onToggle,
    required this.onClear,
  });

  final List<SearchFilterGroup<T>> groups;
  final Set<SearchFilterChipSpec<T>> active;
  final void Function(SearchFilterChipSpec<T>) onToggle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups) ...[
            Row(
              children: [
                Text(g.title, style: theme.textTheme.labelMedium),
                const Spacer(),
                if (g == groups.first && onClear != null)
                  TextButton(
                    onPressed: onClear,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('清空筛选'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final c in g.chips)
                  FilterChip(
                    label: Text(c.label),
                    selected: active.contains(c),
                    onSelected: (_) => onToggle(c),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
