import 'package:flutter/material.dart';

import 'design_tokens.dart';

class BuiltinBadge extends StatelessWidget {
  const BuiltinBadge({super.key, this.label = '内置'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CofferColors.surface3,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: CofferColors.textMuted),
      ),
    );
  }
}
