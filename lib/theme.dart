// ISL (Intelligent Solutions Leaders) brand theme — the single source of truth
// for colours, spacing, and Arabic typography. Widgets pull from here; do not
// hardcode colours in screens.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light palette's actual color values. Kept as real `const`s (unlike
/// [AppColors] itself) so the handful of places that need a genuine
/// compile-time constant — [AppText]'s default parameter values — have one
/// to point at; everything else should read [AppColors].
class _LightColors {
  _LightColors._();

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

  /// Status. `success` is darkened from the original 0xFF2E7D5B (4.05:1 on
  /// `cream` — fails AA normal-text) to 0xFF276E4F (4.96:1) — same hue,
  /// same usage, just dark enough to clear 4.5:1.
  static const Color success = Color(0xFF276E4F);
  static const Color error = Color(0xFFB03A2E);
}

/// Dark palette's actual color values — see [AppColors] for how these get
/// selected at runtime. Mirrors [_LightColors]' field names 1:1 so a screen
/// never needs to know which one it's actually drawing from.
///
/// Approach: the light theme already puts light text ([AppColors.onNavy])
/// on dark navy cards/headers alongside dark text ([AppColors.onCream]) on
/// a light cream page background — two contexts coexisting in one theme.
/// Dark mode collapses to a single context: the page background itself
/// becomes dark (darker than the light theme's navy, so navy-ish surfaces
/// can still sit visibly above it), text becomes uniformly light, and
/// [terracotta] carries over unchanged as the one accent color that isn't
/// asked to serve as a text/background pair.
class AppColorsDark {
  AppColorsDark._();

  /// Page background — deliberately darker than light mode's navy so that
  /// color can still be used as a raised surface (cards/headers) above it.
  static const Color navy = Color(0xFF12181F);
  static const Color navyDark = Color(0xFF0B0F14); // pressed / deepest
  /// Raised surface on the dark background — reuses the light theme's navy
  /// value, so cards read as "the same navy" in both modes.
  static const Color navySoft = Color(0xFF1E2A3A);

  /// "cream" role inverts to a dark, slightly-lighter-than-background
  /// surface — inputs, secondary cards.
  static const Color cream = Color(0xFF12181F);
  static const Color surface = Color(0xFF1C2632);
  static const Color border = Color(0xFF33404F);

  /// Unchanged — verified >= 4.5:1 against both [navy] and [cream] above
  /// for icons/large text/pills (the app's existing usage pattern); NOT
  /// guaranteed at 4.5:1 for small body text in this color on the darkest
  /// background (~4.0:1) — the app never uses it that way today, but a
  /// future call site should check before adding small terracotta text.
  static const Color terracotta = Color(0xFFB5623A);

  static const Color onNavy = Color(0xFFF1ECE1);
  static const Color onCream = Color(0xFFF1ECE1);
  static const Color mutedOnCream = Color(0xFFA8B0BC);
  static const Color mutedOnNavy = Color(0xFFA8B0BC);

  /// Brightened versus light mode's values — verified 6.55:1 (success) and
  /// similarly clear of 4.5:1 (error) against this palette's dark
  /// backgrounds.
  static const Color success = Color(0xFF4FAE82);
  static const Color error = Color(0xFFE0705F);
}

/// Brightness-aware brand colors — the single source every screen reads
/// (`AppColors.navy`, `AppColors.onCream`, ...). [brightness] is kept in
/// sync with the active ThemeMode by MyApp's build() (main.dart) on every
/// rebuild, so these getters resolve to the right palette without needing a
/// BuildContext at the call site — screens keep writing exactly the same
/// `AppColors.x` they always have.
///
/// These are getters, not `static const` — a deliberate trade-off. Any
/// `const Widget(color: AppColors.x)` call site stops compiling once this
/// stops being a compile-time constant; every one of those had its `const`
/// removed as part of wiring this up (see the dark-mode commit). New code
/// must not add `const` back around an `AppColors.x` reference.
class AppColors {
  AppColors._();

  static Brightness brightness = Brightness.light;
  static bool get _dark => brightness == Brightness.dark;

  static Color get navy => _dark ? AppColorsDark.navy : _LightColors.navy;
  static Color get navyDark =>
      _dark ? AppColorsDark.navyDark : _LightColors.navyDark;
  static Color get navySoft =>
      _dark ? AppColorsDark.navySoft : _LightColors.navySoft;

  static Color get cream => _dark ? AppColorsDark.cream : _LightColors.cream;
  static Color get surface =>
      _dark ? AppColorsDark.surface : _LightColors.surface;
  static Color get border =>
      _dark ? AppColorsDark.border : _LightColors.border;

  static Color get terracotta =>
      _dark ? AppColorsDark.terracotta : _LightColors.terracotta;

  static Color get onNavy => _dark ? AppColorsDark.onNavy : _LightColors.onNavy;
  static Color get onCream =>
      _dark ? AppColorsDark.onCream : _LightColors.onCream;
  static Color get mutedOnCream =>
      _dark ? AppColorsDark.mutedOnCream : _LightColors.mutedOnCream;
  static Color get mutedOnNavy =>
      _dark ? AppColorsDark.mutedOnNavy : _LightColors.mutedOnNavy;

  static Color get success =>
      _dark ? AppColorsDark.success : _LightColors.success;
  static Color get error => _dark ? AppColorsDark.error : _LightColors.error;
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
      custom(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  /// For call sites that need a size/weight/height AppText's fixed presets
  /// don't cover — an adjustable reading-font-size slider, a one-off display
  /// glyph, etc. Screens used to reach for `GoogleFonts.tajawal(...)`
  /// directly for these, which skipped the `leadingDistribution: .even` fix
  /// below and brought back the clipped-ascender/descender bug on ش/ت/لا.
  /// Always route custom Tajawal styles through here instead.
  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
    required Color color,
    double? letterSpacing,
  }) =>
      GoogleFonts.tajawal(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
      ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  // These take a nullable color (rather than defaulting the parameter
  // itself to an AppColors.x constant) because AppColors.x is now a
  // brightness-aware getter, not a compile-time constant — resolving the
  // default inside the body means a caller that doesn't pass a color still
  // gets the correct light/dark value for whichever theme is active.

  static TextStyle display({Color? color}) => _tajawal(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.4,
      color: color ?? AppColors.onCream);

  static TextStyle title({Color? color}) => _tajawal(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.45,
      color: color ?? AppColors.onCream);

  static TextStyle cardTitle({Color? color}) => _tajawal(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: color ?? AppColors.onNavy);

  static TextStyle body({Color? color}) => _tajawal(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.6,
      color: color ?? AppColors.onCream);

  static TextStyle label({Color? color}) => _tajawal(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: color ?? AppColors.mutedOnCream);

  static TextStyle button({Color? color}) => _tajawal(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: color ?? AppColors.onNavy);

  /// A secondary line under a primary label (e.g. sub-conditions under a
  /// category name) — ~75% of [body]'s size, muted by default.
  static TextStyle caption({Color? color}) => _tajawal(
      fontSize: 11.25,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color ?? AppColors.mutedOnCream);
}

/// Behavioral/emotional support (StudentProfile.softensErrorMessages):
/// replaces sharp failure wording with a reassuring phrase before it reaches
/// a snackbar/dialog. Substring match, so both a bare word and a full
/// sentence containing it ("حدث خطأ أثناء...") are caught.
class AppMessages {
  AppMessages._();

  static const Map<String, String> _softenedReplacements = {
    'خطأ': 'لم يكتمل، جرّب مرة ثانية',
    'فشل': 'لم يعمل الآن',
    'لم يتم': 'لم يكتمل',
  };

  /// Returns [message] unchanged unless [enabled] (the active profile softens
  /// error messages), in which case the first matching harsh phrase is
  /// replaced with its reassuring counterpart.
  static String soften(String message, {required bool enabled}) {
    if (!enabled) return message;
    for (final entry in _softenedReplacements.entries) {
      if (message.contains(entry.key)) return entry.value;
    }
    return message;
  }
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
