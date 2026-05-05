import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A compact KPI indicator tile for dashboard grids.
///
/// Displays: icon, label, large value, optional subtitle, optional trend widget.
/// Tappable with InkWell for drill-down navigation.
class GwpKpiTile extends StatelessWidget {
  const GwpKpiTile({
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

  /// Optional trailing widget — e.g. a GwpMiniChart or GwpProgressRing.
  final Widget? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: GwpColors.surface1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(GwpSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GwpColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor ?? GwpColors.actionPrimary),
                  const SizedBox(width: GwpSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GwpColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GwpSpacing.sm),
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
                            fontFamily: GwpTypo.monoFont,
                            fontFeatures: GwpTypo.tabularFigures,
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
                              color: GwpColors.textMuted,
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
