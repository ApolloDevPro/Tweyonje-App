/// Spacing & radius tokens — ported from theme.ts
class AppSpacing {
  AppSpacing._();

  // ── Spacing ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
  static const double xxxxxxl = 64;
}

/// Border radius tokens.
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double xxxxl = 32;
  static const double pill = 9999;
}

/// Border width tokens.
class AppBorder {
  AppBorder._();

  static const double thin = 0.5;
  static const double normal = 1;
  static const double medium = 1.5;
  static const double thick = 2;
}

/// Opacity tokens.
class AppOpacity {
  AppOpacity._();

  static const double transparent = 0;
  static const double light = 0.25;
  static const double medium = 0.5;
  static const double heavy = 0.75;
  static const double opaque = 1;
}

/// Animation duration tokens (in milliseconds).
class AppAnimation {
  AppAnimation._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
}
