import 'package:flutter/material.dart';

import '../../domain/valuation/asset_valuator.dart';

class SyncWindowMenuButton extends StatelessWidget {
  const SyncWindowMenuButton({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.tooltip,
    this.child,
  });

  final ValueChanged<SyncWindow> onSelected;
  final bool enabled;
  final String? tooltip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SyncWindow>(
      enabled: enabled,
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final window in SyncWindow.values)
          PopupMenuItem<SyncWindow>(
            value: window,
            child: Text(window.label),
          ),
      ],
      child: child,
    );
  }
}
