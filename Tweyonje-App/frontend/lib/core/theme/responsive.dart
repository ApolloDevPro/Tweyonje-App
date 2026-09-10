import 'package:flutter/widgets.dart';

/// Material 3 window size classes for adaptive layouts.
enum AppWindowSize { compact, medium, expanded }

/// Breakpoints (Material 3 spec):
///  - compact:   width < 600
///  - medium:    600 <= width < 840
///  - expanded:  width >= 840
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

/// Helpers to read the current screen class without guessing.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  AppWindowSize get windowSize {
    if (screenWidth >= ResponsiveBreakpoints.medium) return AppWindowSize.expanded;
    if (screenWidth >= ResponsiveBreakpoints.compact) return AppWindowSize.medium;
    return AppWindowSize.compact;
  }

  bool get isCompact => windowSize == AppWindowSize.compact;
  bool get isMedium => windowSize == AppWindowSize.medium;
  bool get isExpanded => windowSize == AppWindowSize.expanded;
  bool get isTabletOrWider => !isCompact;

  /// Recommended body width cap: single-column phone UI, wider on tablets.
  double get contentMaxWidth {
    switch (windowSize) {
      case AppWindowSize.compact:
        return double.infinity;
      case AppWindowSize.medium:
        return 880;
      case AppWindowSize.expanded:
        return 1120;
    }
  }
}