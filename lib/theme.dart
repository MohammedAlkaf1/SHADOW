// ISL (Intelligent Solutions Leaders) brand theme — the single source of truth
// for colours, spacing, and Arabic typography. Widgets pull from here; do not
// hardcode colours in screens.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  /// Primary — deep navy: headers, primary buttons, mode-card backgrounds.
  static const Color navy = Color(0xFF1E2A3A);
  static const Color navyDark = Color(0xFF16202C); // pressed / deep surfaces
  static const Color navySoft = Color(0xFF2A3949); // raised surfaces on navy

  /// Secondary — warm cream: page backgrounds and surfaces.
  static const Color cream = Color(0xFFECE7DC);
  static const Color surface = Color(0xFFF5F1E9); // cards / inputs on cream
  static const Color border = Color(0xFFD9D2C4);

  /// Accent — muted terracotta. Use sparingly: one highlight per screen.
  static const Color terracotta = Color(0xFFB5623A);

  /// Text — always AA contrast (>= 4.5:1) on its background.
  static const Color onNavy = Color(0xFFF1ECE1); // cream text on navy
  static const Color onCream = Color(0xFF1E2A3A); // navy text on cream
  static const Color mutedOnCream = Color(0xFF5B6470);
  static const Color mutedOnNavy = Color(0xFFB2BAC6);

  /// Status.
  static const Color success = Color(0xFF2E7D5B);
  static const Color error = Color(0xFFB03A2E);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double cardRadius = 20;
  static const double pill = 999;

  /// Accessibility: minimum interactive target.
  static const double minTap = 48;
}

/// Arabic-first typography (Tajawal). Sizes honour the OS / in-app text scale
/// because Flutter's Text applies MediaQuery.textScaler on top of these.
class AppText {
  AppText._();

  // Arabic glyphs (e.g. the tall marks on ش/ت/ث) sit higher than Latin, so a
  // tight line box clips their tops. `TextLeadingDistribution.even` splits the
  // extra line height evenly above and below the glyphs instead of piling it
  // under them, and the slightly taller `height` values give the ascenders room.
  static TextStyle _tajawal({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
  }) =>
      GoogleFonts.tajawal(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  static TextStyle display({Color color = AppColors.onCream}) => _tajawal(
      fontSize: 26, fontWeight: FontWeight.w800, height: 1.4, color: color);

  static TextStyle title({Color color = AppColors.onCream}) => _tajawal(
      fontSize: 20, fontWeight: FontWeight.w700, height: 1.45, color: color);

  static TextStyle cardTitle({Color color = AppColors.onNavy}) => _tajawal(
      fontSize: 18, fontWeight: FontWeight.w700, height: 1.4, color: color);

  static TextStyle body({Color color = AppColors.onCream}) => _tajawal(
      fontSize: 15, fontWeight: FontWeight.w500, height: 1.6, color: color);

  static TextStyle label({Color color = AppColors.mutedOnCream}) => _tajawal(
      fontSize: 13, fontWeight: FontWeight.w600, height: 1.5, color: color);

  static TextStyle button({Color color = AppColors.onNavy}) => _tajawal(
      fontSize: 16, fontWeight: FontWeight.w700, height: 1.4, color: color);
}

/// Shared surface styles so every screen uses the same card look.
class AppDecor {
  AppDecor._();

  static BoxDecoration navyCard() => BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      );

  static BoxDecoration creamCard() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      );
}
