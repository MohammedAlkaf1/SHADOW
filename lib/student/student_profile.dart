// Student adaptation profile — the two fields that drive how every mode
// behaves for a given student. Values come from the specialist-reviewed
// record on the platform (not yet built); until then they default or come
// from --dart-define for testing. See docs/شادو_خطة_التكيف_الشاملة.md.
//
// Phase 1 only: this file defines the data model. Nothing reads it yet —
// no mode UI and no Gemini prompt is adapted in this phase.

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
