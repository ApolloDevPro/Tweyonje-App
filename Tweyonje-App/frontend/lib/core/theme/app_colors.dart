import 'package:flutter/material.dart';

/// Tweyonje app color palette — ported from theme.ts
class AppColors {
  AppColors._();

  // ── Primary (green — brand identity) ──
  static const Color primary = Color(0xFF0A8F3C);
  static const Color primaryDark = Color(0xFF065F24);
  static const Color primaryLight = Color(0xFF34C759);
  static const Color primarySoft = Color(0xFFE8F8EE);
  static const List<Color> primaryGradient = [primary, primaryDark];

  // ── Accent (orange) ──
  static const Color accent = Color(0xFFFF9500);
  static const Color accentDark = Color(0xFFCC7700);
  static const Color accentLight = Color(0xFFFFB84D);
  static const Color accentSoft = Color(0xFFFFF4E5);

  // ── Backgrounds ──
  static const Color background = Color(0xFFF8FAFB);
  static const Color backgroundSecondary = Color(0xFFF1F5F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F4);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text ──
  static const Color text = Color(0xFF0F1A2E);
  static const Color textSecondary = Color(0xFF5A6B7F);
  static const Color textTertiary = Color(0xFF8E9BB0);
  static const Color textMuted = Color(0xFF8E9BB0);
  static const Color textLight = Color(0xFFB0BEC5);
  static const Color textDisabled = Color(0xFFC7D0DC);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Borders ──
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF0A8F3C);

  // ── Semantic — Danger ──
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  // ── Semantic — Error (alias for Danger) ──
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorSoft = Color(0xFFFEF2F2);

  // ── Semantic — Success ──
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successSoft = Color(0xFFECFDF5);

  // ── Semantic — Warning ──
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFED7AA);
  static const Color warningSoft = Color(0xFFFFFBEB);

  // ── Semantic — Info ──
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFBFDBFE);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // ── Overlays ──
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x4D000000);
  static const Color overlayDark = Color(0xB3000000);

  // ── Glass ──
  static const Color glass = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0x99000000);

  // ── Material Color Swatch (for ThemeData) ──
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF0A8F3C,
    <int, Color>{
      50: Color(0xFFE8F8EE),
      100: Color(0xFFC6EDCF),
      200: Color(0xFFA0E1AF),
      300: Color(0xFF79D58E),
      400: Color(0xFF5CCC76),
      500: Color(0xFF0A8F3C),
      600: Color(0xFF098236),
      700: Color(0xFF07722E),
      800: Color(0xFF065F24),
      900: Color(0xFF044416),
    },
  );
}

/// Pre-defined gradients used across the app.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accent, AppColors.accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.success, AppColors.successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [AppColors.danger, AppColors.dangerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient info = LinearGradient(
    colors: [AppColors.info, AppColors.infoDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtle = LinearGradient(
    colors: [AppColors.background, AppColors.backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
