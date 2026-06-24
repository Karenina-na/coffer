import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A compact KPI indicator tile for dashboard grids.
///
/// Displays: icon, label, large value, optional subtitle, optional trend widget.
/// Tappable with InkWell for drill-down navigation.
class CofferKpiTile extends StatelessWidget {
  const CofferKpiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.iconColor,
    this.onTap,
    this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Optional trailing widget — e.g. a CofferMiniChart or CofferProgressRing.
  final Widget? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: CofferColors.surface1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(CofferSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CofferColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor ?? CofferColors.actionPrimary),
                  const SizedBox(width: CofferSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CofferColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CofferSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: CofferTypo.monoFont,
                            fontFeatures: CofferTypo.tabularFigures,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: CofferColors.textMuted,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trend,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
