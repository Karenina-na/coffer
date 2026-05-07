import 'package:flutter/widgets.dart';

class FloatingNavLayout {
  FloatingNavLayout._();

  static const barHeight = 64.0;
  static const bottomGap = 12.0;

  static double totalFloatingHeight(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.paddingOf(context).bottom;
  }
}
