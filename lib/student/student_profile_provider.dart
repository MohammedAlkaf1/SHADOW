// Holds the current StudentProfile in app state (Provider/ChangeNotifier,
// matching the rest of the project — no Riverpod).
//
// Singleton, matching FFAppState's pattern in lib/app_state.dart: reachable
// both via Provider in the widget tree (context.watch<StudentProfileProvider>())
// and via direct StudentProfileProvider() calls from non-widget code (custom_code
// actions calling Gemini have no BuildContext) — see StudentProfile.current.

import 'package:flutter/foundation.dart';

import 'student_profile.dart';
import '/services/adaptation_directives.dart';

class StudentProfileProvider extends ChangeNotifier {
  static StudentProfileProvider _instance =
      StudentProfileProvider._(_loadFromEnvironment());

  factory StudentProfileProvider() => _instance;

  StudentProfileProvider._(this._profile);

  StudentProfile _profile;
  StudentProfile get profile => _profile;
  StudentCategory get category => _profile.category;
  SupportLevel get supportLevel => _profile.supportLevel;

  /// Builds the initial profile: --dart-define values win when present,
  /// otherwise the plan's testing default (learningDifficulties / moderate).
  ///
  ///   flutter run --dart-define=STUDENT_CATEGORY=neurodevelopmental \
  ///               --dart-define=STUDENT_SUPPORT_LEVEL=intensive
  static StudentProfile _loadFromEnvironment() {
    const categoryEnv = String.fromEnvironment('STUDENT_CATEGORY');
    const supportLevelEnv = String.fromEnvironment('STUDENT_SUPPORT_LEVEL');

    final category = StudentCategoryParsing.fromName(categoryEnv) ??
        StudentProfile.defaultProfile.category;
    final supportLevel = SupportLevelParsing.fromName(supportLevelEnv) ??
        StudentProfile.defaultProfile.supportLevel;

    return StudentProfile(category: category, supportLevel: supportLevel);
  }

  /// Used by the debug-only Developer Tools screen to switch profiles live
  /// without restarting the app.
  void setCategory(StudentCategory category) {
    if (category == _profile.category) return;
    _profile = _profile.copyWith(category: category);
    notifyListeners();
  }

  void setSupportLevel(SupportLevel level) {
    if (level == _profile.supportLevel) return;
    _profile = _profile.copyWith(supportLevel: level);
    notifyListeners();
  }

  /// Hydrates this profile from a real platform fetch (or a locally cached
  /// copy of one — see PlatformClient.getStudentProfile). This is what makes
  /// a logged-in real student's profile stop being locally-computed from the
  /// category/supportLevel enums: from this point on, every StudentProfile
  /// getter that has a directives-aware branch will use [directives]
  /// instead. [category]/[supportLevel] themselves are left at whatever they
  /// were (dev-tools default) — they're no longer the source of truth once
  /// [directives] is set, but keeping them avoids making them nullable
  /// throughout the codebase.
  void applyPlatformProfile({
    required List<String> enabledTools,
    required AdaptationDirectives directives,
  }) {
    _profile = _profile.copyWith(
      enabledTools: enabledTools,
      directives: directives,
    );
    notifyListeners();
  }

  /// Reverts to the local enum-based profile — used on logout so a stale
  /// platform session's directives don't linger for whichever demo/dev
  /// profile comes next.
  void clearPlatformProfile() {
    _profile = StudentProfile(
      category: _profile.category,
      supportLevel: _profile.supportLevel,
    );
    notifyListeners();
  }
}
