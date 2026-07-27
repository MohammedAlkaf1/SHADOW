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

  // Category style rules (Phase 4 — طبقة التصنيف فوق مستوى الدعم). These are
  // a UI-only style layer, separate from the Gemini prompt's "اضبط تركيزك حسب
  // التصنيف" section (adaptive_prompts.dart) — do not merge the two.

  /// Neurodevelopmental AND mild-cognitive: the plan states the same rule
  /// twice under two different category headings ("لا يُعرض أكثر من عنصر
  /// تفاعلي رئيسي واحد" / "الأزرار الثانوية مخفية افتراضياً؛ زر واحد رئيسي
  /// فقط") — merged into one helper.
  bool get hidesSecondaryActions =>
      category == StudentCategory.neurodevelopmental ||
      category == StudentCategory.mildCognitive;

  /// Neurodevelopmental: no pulsing/bouncing animation (e.g. the deaf-mode
  /// waveform) — render the same visual statically instead.
  bool get usesStaticAnimations =>
      category == StudentCategory.neurodevelopmental;

  /// Neurodevelopmental: reduce in-app notifications (snackbars) to the
  /// minimum — non-essential confirmations are suppressed; messages that
  /// explain why something didn't work still show (see [AppMessages] call
  /// sites: essential: true).
  bool get minimizesNotifications =>
      category == StudentCategory.neurodevelopmental;

  /// Learning difficulties: a "اقرأ لي" (read aloud / TTS) button appears on
  /// screens with long text.
  bool get showsReadAloudButton =>
      category == StudentCategory.learningDifficulties;

  /// Learning difficulties: learning-support mode auto-runs the summary
  /// action as soon as a document loads, no button press needed.
  bool get autoSummarizesByDefault =>
      category == StudentCategory.learningDifficulties;

  /// Mild cognitive: every action button shows a permanent caption under it
  /// explaining what it does (not a hover/long-press tooltip — always
  /// visible).
  bool get showsPermanentTooltips =>
      category == StudentCategory.mildCognitive;

  /// Communication/language: deaf mode only gets a "صياغة رسالة للأستاذ"
  /// button (compose a polite message to the lecturer via Gemini).
  bool get showsMessageAssistant =>
      category == StudentCategory.communicationLanguage;

  /// Behavioral/emotional: sharp failure wording is replaced with a
  /// reassuring phrase (see AppMessages.soften in lib/theme.dart).
  bool get softensErrorMessages =>
      category == StudentCategory.behavioralEmotional;

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
