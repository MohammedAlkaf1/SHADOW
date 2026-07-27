// Student adaptation profile — the two fields that drive how every mode
// behaves for a given student. Values come from the specialist-reviewed
// record on the platform (not yet built); until then they default or come
// from --dart-define for testing. See docs/شادو_خطة_التكيف_الشاملة.md.

import 'student_profile_provider.dart';

/// The five general classifications a specialist can assign. Values match
/// the plan document exactly; do not rename without updating the doc.
enum StudentCategory {
  neurodevelopmental,
  learningDifficulties,
  mildCognitive,
  communicationLanguage,
  behavioralEmotional,
}

/// Support intensity. Ordered light < moderate < intensive — [SupportLevel]
/// comparison helpers below rely on declaration order.
enum SupportLevel {
  light,
  moderate,
  intensive,
}

extension StudentCategoryParsing on StudentCategory {
  static StudentCategory? fromName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final value in StudentCategory.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

extension SupportLevelParsing on SupportLevel {
  static SupportLevel? fromName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final value in SupportLevel.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// The literal Arabic labels from docs/شادو_خطة_التكيف_الشاملة.md — used both
/// inside adaptive Gemini prompts (student data block) and in the debug-only
/// Developer Tools screen. Single source so the two never drift apart.
extension StudentCategoryArabic on StudentCategory {
  String get arabicLabel => switch (this) {
        StudentCategory.neurodevelopmental => 'اضطرابات النمو العصبي',
        StudentCategory.learningDifficulties => 'صعوبات التعلم',
        StudentCategory.mildCognitive => 'الإعاقات الإدراكية الخفيفة',
        StudentCategory.communicationLanguage => 'اضطرابات التواصل واللغة',
        StudentCategory.behavioralEmotional => 'الاضطرابات السلوكية والانفعالية',
      };
}

extension SupportLevelArabic on SupportLevel {
  String get arabicLabel => switch (this) {
        SupportLevel.light => 'دعم خفيف',
        SupportLevel.moderate => 'دعم متوسط',
        SupportLevel.intensive => 'دعم مكثف',
      };
}

/// A student's adaptation profile: what to adapt for (category) and how
/// strongly (support level). Immutable; use [copyWith] to change a field.
class StudentProfile {
  const StudentProfile({
    required this.category,
    required this.supportLevel,
  });

  final StudentCategory category;
  final SupportLevel supportLevel;

  static const defaultProfile = StudentProfile(
    category: StudentCategory.learningDifficulties,
    supportLevel: SupportLevel.moderate,
  );

  /// The active student's profile right now, read from the app-wide
  /// [StudentProfileProvider] singleton. Lets non-widget code (custom_code
  /// actions calling Gemini, which have no BuildContext) read the profile
  /// without the level being threaded manually through every call —
  /// mirrors how the project already reads FFAppState() outside the widget
  /// tree.
  static StudentProfile get current => StudentProfileProvider().profile;

  bool isOfCategory(StudentCategory other) => category == other;

  /// True if this profile's support level is at or above [level] — e.g.
  /// `isAtLeast(SupportLevel.moderate)` is true for moderate and intensive.
  bool isAtLeast(SupportLevel level) =>
      supportLevel.index >= level.index;

  bool get isLight => supportLevel == SupportLevel.light;
  bool get isModerate => supportLevel == SupportLevel.moderate;
  bool get isIntensive => supportLevel == SupportLevel.intensive;

  StudentProfile copyWith({
    StudentCategory? category,
    SupportLevel? supportLevel,
  }) =>
      StudentProfile(
        category: category ?? this.category,
        supportLevel: supportLevel ?? this.supportLevel,
      );

  @override
  String toString() =>
      'StudentProfile(category: ${category.name}, supportLevel: ${supportLevel.name})';
}
