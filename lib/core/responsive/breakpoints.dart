import 'package:flutter/widgets.dart';

enum WindowSizeClass { compact, medium, expanded }

class AppBreakpoints {
  const AppBreakpoints._();

  static const compact = 600.0;
  static const expanded = 1024.0;

  static WindowSizeClass ofWidth(double width) {
    if (width < compact) return WindowSizeClass.compact;
    if (width < expanded) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  static WindowSizeClass of(BuildContext context) {
    return ofWidth(MediaQuery.sizeOf(context).width);
  }
}
