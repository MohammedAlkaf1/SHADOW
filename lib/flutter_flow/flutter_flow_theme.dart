// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  late Color primaryContainer;
  late Color transparent;
  late Color surfaceVariant;
  late Color onSuccess;
  late Color fullContrast;
  late Color onError;
  late Color onWarning;
  late Color onBackground;
  late Color onPrimaryContainer;
  late Color onAccent;
  late Color onInfo;
  late Color onSurfaceVariant;
  late Color onPrimary;
  late Color secondaryContainer;
  late Color onAccentContainer;
  late Color onSurface;
  late Color onSecondaryContainer;
  late Color accentContainer;
  late Color onSecondary;
  late Color primary40;
  late Color primary60;
  late Color error27;
  late Color surface90;
  late Color onPrimary80;
  late Color onPrimary20;
  late Color onPrimary30;
  late Color fullContrast53;

  FFDesignTokens get designToken => FFDesignTokens(this);

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  bool get displayLargeIsCustom => typography.displayLargeIsCustom;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  bool get displayMediumIsCustom => typography.displayMediumIsCustom;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  bool get displaySmallIsCustom => typography.displaySmallIsCustom;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  bool get headlineLargeIsCustom => typography.headlineLargeIsCustom;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  bool get headlineMediumIsCustom => typography.headlineMediumIsCustom;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  bool get headlineSmallIsCustom => typography.headlineSmallIsCustom;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  bool get titleLargeIsCustom => typography.titleLargeIsCustom;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  bool get titleMediumIsCustom => typography.titleMediumIsCustom;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  bool get titleSmallIsCustom => typography.titleSmallIsCustom;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  bool get labelLargeIsCustom => typography.labelLargeIsCustom;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  bool get labelMediumIsCustom => typography.labelMediumIsCustom;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  bool get labelSmallIsCustom => typography.labelSmallIsCustom;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  bool get bodyLargeIsCustom => typography.bodyLargeIsCustom;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  bool get bodyMediumIsCustom => typography.bodyMediumIsCustom;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  bool get bodySmallIsCustom => typography.bodySmallIsCustom;
  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => ThemeTypography(this);
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF003651);
  late Color secondary = const Color(0xFFC16325);
  late Color tertiary = const Color(0xFFC16325);
  late Color alternate = const Color(0xFFCAC1B1);
  late Color primaryText = const Color(0xFF003651);
  late Color secondaryText = const Color(0xFF44546A);
  late Color primaryBackground = const Color(0xFFF5F0E8);
  late Color secondaryBackground = const Color(0xFFFFFFFF);
  late Color accent1 = const Color(0x00000000);
  late Color accent2 = const Color(0x00000000);
  late Color accent3 = const Color(0xFF6B7A8D);
  late Color accent4 = const Color(0x00000000);
  late Color success = const Color(0xFF2E7D32);
  late Color warning = const Color(0xFFF57C00);
  late Color error = const Color(0xFFD32F2F);
  late Color info = const Color(0xFF1976D2);

  late Color primaryContainer = const Color(0x1A003651);
  late Color transparent = const Color(0x00000000);
  late Color surfaceVariant = const Color(0xFFE8E2D8);
  late Color onSuccess = const Color(0xFFFFFFFF);
  late Color fullContrast = const Color(0xFF000000);
  late Color onError = const Color(0xFFFFFFFF);
  late Color onWarning = const Color(0xFFFFFFFF);
  late Color onBackground = const Color(0xFF003651);
  late Color onPrimaryContainer = const Color(0xFF003651);
  late Color onAccent = const Color(0xFFFFFFFF);
  late Color onInfo = const Color(0xFFFFFFFF);
  late Color onSurfaceVariant = const Color(0xFF44546A);
  late Color onPrimary = const Color(0xFFFFFFFF);
  late Color secondaryContainer = const Color(0x1AC16325);
  late Color onAccentContainer = const Color(0xFF003651);
  late Color onSurface = const Color(0xFF003651);
  late Color onSecondaryContainer = const Color(0xFF003651);
  late Color accentContainer = const Color(0x1AC16325);
  late Color onSecondary = const Color(0xFFFFFFFF);
  late Color primary40 = const Color(0x66003651);
  late Color primary60 = const Color(0x99003651);
  late Color error27 = const Color(0x45D32F2F);
  late Color surface90 = const Color(0xE6FFFFFF);
  late Color onPrimary80 = const Color(0xCCFFFFFF);
  late Color onPrimary20 = const Color(0x33FFFFFF);
  late Color onPrimary30 = const Color(0x4DFFFFFF);
  late Color fullContrast53 = const Color(0x87000000);
}

abstract class Typography {
  String get displayLargeFamily;
  bool get displayLargeIsCustom;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  bool get displayMediumIsCustom;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  bool get displaySmallIsCustom;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  bool get headlineLargeIsCustom;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  bool get headlineMediumIsCustom;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  bool get headlineSmallIsCustom;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  bool get titleLargeIsCustom;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  bool get titleMediumIsCustom;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  bool get titleSmallIsCustom;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  bool get labelLargeIsCustom;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  bool get labelMediumIsCustom;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  bool get labelSmallIsCustom;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  bool get bodyLargeIsCustom;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  bool get bodyMediumIsCustom;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  bool get bodySmallIsCustom;
  TextStyle get bodySmall;
}

class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Cairo';
  bool get displayLargeIsCustom => false;
  TextStyle get displayLarge => GoogleFonts.cairo(
        fontWeight: FontWeight.w800,
        fontSize: 58.0,
        height: 1.2,
      );
  String get displayMediumFamily => 'Cairo';
  bool get displayMediumIsCustom => false;
  TextStyle get displayMedium => GoogleFonts.cairo(
        fontWeight: FontWeight.w800,
        fontSize: 46.0,
        height: 1.2,
      );
  String get displaySmallFamily => 'Cairo';
  bool get displaySmallIsCustom => false;
  TextStyle get displaySmall => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 38.0,
        height: 1.2,
      );
  String get headlineLargeFamily => 'Cairo';
  bool get headlineLargeIsCustom => false;
  TextStyle get headlineLarge => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 34.0,
        height: 1.3,
      );
  String get headlineMediumFamily => 'Cairo';
  bool get headlineMediumIsCustom => false;
  TextStyle get headlineMedium => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 28.0,
        height: 1.3,
      );
  String get headlineSmallFamily => 'Cairo';
  bool get headlineSmallIsCustom => false;
  TextStyle get headlineSmall => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
        height: 1.3,
      );
  String get titleLargeFamily => 'Cairo';
  bool get titleLargeIsCustom => false;
  TextStyle get titleLarge => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 22.0,
        height: 1.4,
      );
  String get titleMediumFamily => 'Cairo';
  bool get titleMediumIsCustom => false;
  TextStyle get titleMedium => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
        height: 1.4,
      );
  String get titleSmallFamily => 'Cairo';
  bool get titleSmallIsCustom => false;
  TextStyle get titleSmall => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
        height: 1.4,
      );
  String get labelLargeFamily => 'Cairo';
  bool get labelLargeIsCustom => false;
  TextStyle get labelLarge => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
        height: 1.4,
      );
  String get labelMediumFamily => 'Cairo';
  bool get labelMediumIsCustom => false;
  TextStyle get labelMedium => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 14.0,
        height: 1.4,
      );
  String get labelSmallFamily => 'Cairo';
  bool get labelSmallIsCustom => false;
  TextStyle get labelSmall => GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 12.0,
        height: 1.4,
      );
  String get bodyLargeFamily => 'Cairo';
  bool get bodyLargeIsCustom => false;
  TextStyle get bodyLarge => GoogleFonts.cairo(
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
        height: 1.6,
      );
  String get bodyMediumFamily => 'Cairo';
  bool get bodyMediumIsCustom => false;
  TextStyle get bodyMedium => GoogleFonts.cairo(
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        height: 1.6,
      );
  String get bodySmallFamily => 'Cairo';
  bool get bodySmallIsCustom => false;
  TextStyle get bodySmall => GoogleFonts.cairo(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 1.5,
      );
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF81C784);
  late Color secondary = const Color(0xFF64B5F6);
  late Color tertiary = const Color(0xFFFFB74D);
  late Color alternate = const Color(0xFF444444);
  late Color primaryText = const Color(0xFFFFFFFF);
  late Color secondaryText = const Color(0xFFBDBDBD);
  late Color primaryBackground = const Color(0xFF121212);
  late Color secondaryBackground = const Color(0xFF242424);
  late Color accent1 = const Color(0x00000000);
  late Color accent2 = const Color(0x00000000);
  late Color accent3 = const Color(0xFF888888);
  late Color accent4 = const Color(0x00000000);
  late Color success = const Color(0xFF66BB6A);
  late Color warning = const Color(0xFFFFA726);
  late Color error = const Color(0xFFEF5350);
  late Color info = const Color(0xFF42A5F5);

  late Color primaryContainer = const Color(0x2481C784);
  late Color transparent = const Color(0x00000000);
  late Color surfaceVariant = const Color(0xFF333333);
  late Color onSuccess = const Color(0xFFFFFFFF);
  late Color fullContrast = const Color(0xFFFFFFFF);
  late Color onError = const Color(0xFFFFFFFF);
  late Color onWarning = const Color(0xFFFFFFFF);
  late Color onBackground = const Color(0xFFFFFFFF);
  late Color onPrimaryContainer = const Color(0xFFFFFFFF);
  late Color onAccent = const Color(0xFF000000);
  late Color onInfo = const Color(0xFFFFFFFF);
  late Color onSurfaceVariant = const Color(0xFFBDBDBD);
  late Color onPrimary = const Color(0xFFFFFFFF);
  late Color secondaryContainer = const Color(0x2464B5F6);
  late Color onAccentContainer = const Color(0xFFFFFFFF);
  late Color onSurface = const Color(0xFFFFFFFF);
  late Color onSecondaryContainer = const Color(0xFFFFFFFF);
  late Color accentContainer = const Color(0x24FFB74D);
  late Color onSecondary = const Color(0xFFFFFFFF);
  late Color primary40 = const Color(0x6681C784);
  late Color primary60 = const Color(0x9981C784);
  late Color error27 = const Color(0x45EF5350);
  late Color surface90 = const Color(0xE6242424);
  late Color onPrimary80 = const Color(0xCCFFFFFF);
  late Color onPrimary20 = const Color(0x33FFFFFF);
  late Color onPrimary30 = const Color(0x4DFFFFFF);
  late Color fullContrast53 = const Color(0x87FFFFFF);
}

class FFDesignTokens {
  const FFDesignTokens(this.theme);
  final FlutterFlowTheme theme;
  FFSpacing get spacing => const FFSpacing();
  FFRadius get radius => const FFRadius();
  FFShadows get shadow => FFShadows(theme);
}

class FFSpacing {
  const FFSpacing();
  double get none => 0.0;
  double get xs => 6.0;
  double get sm => 12.0;
  double get md => 20.0;
  double get lg => 32.0;
  double get xl => 40.0;
  double get xxl => 56.0;
  double get xxxl => 72.0;
}

class FFRadius {
  const FFRadius();
  double get none => 0.0;
  double get xs => 4.0;
  double get sm => 8.0;
  double get md => 16.0;
  double get lg => 24.0;
  double get xl => 32.0;
  double get xxl => 48.0;
  double get full => 9999.0;
}

class FFShadows {
  const FFShadows(this.theme);
  final FlutterFlowTheme theme;
  BoxShadow get md => const BoxShadow(
      blurRadius: 16.0,
      color: const Color(0x26000000),
      offset: const Offset(0.0, 8.0),
      spreadRadius: 0.0);
  BoxShadow get xs => const BoxShadow(
      blurRadius: 4.0,
      color: const Color(0x1A000000),
      offset: const Offset(0.0, 2.0),
      spreadRadius: 0.0);
  BoxShadow get xl => const BoxShadow(
      blurRadius: 32.0,
      color: const Color(0x33000000),
      offset: const Offset(0.0, 16.0),
      spreadRadius: 0.0);
  BoxShadow get xxl => const BoxShadow(
      blurRadius: 48.0,
      color: const Color(0x40000000),
      offset: const Offset(0.0, 24.0),
      spreadRadius: 0.0);
  BoxShadow get lg => const BoxShadow(
      blurRadius: 24.0,
      color: const Color(0x33000000),
      offset: const Offset(0.0, 12.0),
      spreadRadius: 0.0);
  BoxShadow get sm => const BoxShadow(
      blurRadius: 8.0,
      color: const Color(0x26000000),
      offset: const Offset(0.0, 4.0),
      spreadRadius: 0.0);
  BoxShadow get none => const BoxShadow(
      blurRadius: 0.0,
      color: const Color(0x00000000),
      offset: const Offset(0.0, 0.0),
      spreadRadius: 0.0);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
  }) {
    if (useGoogleFonts && fontFamily != null) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          );
  }
}
