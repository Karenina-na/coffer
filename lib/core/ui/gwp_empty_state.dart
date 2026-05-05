import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Actionable empty / error / loading states per DESIGN.md §4.7.
class GwpEmptyState extends StatelessWidget {
  const GwpEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Error variant with retry.
  const factory GwpEmptyState.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) = _ErrorState;

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: GwpColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends GwpEmptyState {
  const _ErrorState({
    super.key,
    required String message,
    VoidCallback? onRetry,
  }) : super(
          icon: Icons.error_outline,
          title: message,
          actionLabel: onRetry != null ? '重试' : null,
          onAction: onRetry,
        );
}
