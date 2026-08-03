// Student adaptation profile — the two fields that drive how every mode
// behaves for a given student. Values come from the specialist-reviewed
// record on the platform; until a real platform session is loaded they
// default or come from --dart-define for testing/dev-tools. See
// docs/شادو_خطة_التكيف_الشاملة.md and (platform side)
// D:\Shadow\platform\docs\API.md's AdaptationDirectives section.
//
// PLATFORM INTEGRATION NOTE: the platform never sends this app the raw
// category/supportLevel for a real logged-in student — only opaque
// "adaptation directives" (see adaptation_directives.dart) computed
// server-side. [directives], when non-null, is that platform-fetched data.
// The [category]/[supportLevel] enum fields below still exist and are still
// used directly for the debug-only Developer Tools screen and as the
// pre-login/offline-with-no-cache fallback — but for a real logged-in
// student, every derived getter below prefers [directives] when it's
// present, falling back to the enum-based computation only when it's null.

import 'student_profile_provider.dart';
import '/services/adaptation_directives.dart';

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

  /// The specific conditions each category covers — literal text from the
  /// plan doc / the original classification file, not hardcoded per screen.
  /// Kept here (not in the Developer Tools widget) so the platform's future
  /// real advisor screen can reuse it verbatim.
  String get conditions => switch (this) {
        StudentCategory.neurodevelopmental =>
          'التوحد، فرط الحركة وتشتت الانتباه',
        StudentCategory.learningDifficulties =>
          'صعوبات القراءة، الكتابة، الحساب، الفهم الأكاديمي',
        StudentCategory.mildCognitive => 'الإعاقة الذهنية البسيطة',
        StudentCategory.communicationLanguage =>
          'صعوبات النطق، الفهم اللغوي، التعبير',
        StudentCategory.behavioralEmotional =>
          'مشكلات السلوك، الاندفاع، القلق داخل البيئة التعليمية',
      };
}

extension SupportLevelArabic on SupportLevel {
  String get arabicLabel => switch (this) {
        SupportLevel.light => 'دعم خفيف',
        SupportLevel.moderate => 'دعم متوسط',
        SupportLevel.intensive => 'دعم مكثف',
      };
}

/// English counterparts of [StudentCategoryArabic]/[SupportLevelArabic] —
/// used by the English Gemini prompts in adaptive_prompts.dart when the
/// student's app-language setting is English. Same values, same meaning,
/// just the language the "بيانات الطالب" / "Student data" block is written
/// in — the confidentiality rule (never reveal this to the student) applies
/// identically in both languages.
extension StudentCategoryEnglish on StudentCategory {
  String get englishLabel => switch (this) {
        StudentCategory.neurodevelopmental => 'Neurodevelopmental disorders',
        StudentCategory.learningDifficulties => 'Learning difficulties',
        StudentCategory.mildCognitive => 'Mild cognitive disabilities',
        StudentCategory.communicationLanguage =>
          'Communication and language disorders',
        StudentCategory.behavioralEmotional =>
          'Behavioral and emotional disorders',
      };
}

extension SupportLevelEnglish on SupportLevel {
  String get englishLabel => switch (this) {
        SupportLevel.light => 'Light support',
        SupportLevel.moderate => 'Moderate support',
        SupportLevel.intensive => 'Intensive support',
      };
}

/// A student's adaptation profile: what to adapt for (category) and how
/// strongly (support level). Immutable; use [copyWith] to change a field.
class StudentProfile {
  const StudentProfile({
    required this.category,
    required this.supportLevel,
    this.directives,
    this.enabledTools = const [],
  });

  final StudentCategory category;
  final SupportLevel supportLevel;

  /// Platform-computed adaptation directives for a real logged-in student.
  /// Null before login, when offline with nothing cached yet, or in
  /// dev-tools/demo mode — callers fall back to the enum-based rules.
  final AdaptationDirectives? directives;

  /// ToolCode strings enabled on the student's approved SupportPlan,
  /// straight from the platform (see docs/API.md — includes both the 8
  /// granular tool codes and the 4 mode-level codes DEAF_MODE/VISUAL_MODE/
  /// LEARNING_MODE/PHYSICAL_MODE). Empty before a platform profile is ever
  /// loaded.
  final List<String> enabledTools;

  /// True once this profile reflects a real platform fetch (or cache),
  /// rather than the local enum defaults.
  bool get isPlatformLinked => directives != null;

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
  /// فقط") — merged into one helper. Prefers the platform directive when a
  /// real session is loaded, else falls back to the enum-based rule.
  bool get hidesSecondaryActions => directives != null
      ? directives!.categoryLayer.maxOneInteractiveElementPerScreen
      : (category == StudentCategory.neurodevelopmental ||
          category == StudentCategory.mildCognitive);

  /// Neurodevelopmental: no pulsing/bouncing animation (e.g. the deaf-mode
  /// waveform) — render the same visual statically instead.
  bool get usesStaticAnimations => directives != null
      ? directives!.categoryLayer.hidesNonEssentialVisualElements
      : category == StudentCategory.neurodevelopmental;

  /// Neurodevelopmental: reduce in-app notifications (snackbars) to the
  /// minimum — non-essential confirmations are suppressed; messages that
  /// explain why something didn't work still show (see [AppMessages] call
  /// sites: essential: true).
  bool get minimizesNotifications => directives != null
      ? directives!.categoryLayer.reducesNotifications
      : category == StudentCategory.neurodevelopmental;

  /// Learning difficulties: a "اقرأ لي" (read aloud / TTS) button appears on
  /// screens with long text.
  bool get showsReadAloudButton => directives != null
      ? directives!.categoryLayer.ttsSupportEverywhere
      : category == StudentCategory.learningDifficulties;

  /// Learning difficulties: learning-support mode auto-runs the summary
  /// action as soon as a document loads, no button press needed.
  bool get autoSummarizesByDefault => directives != null
      ? directives!.categoryLayer.autoSummarizesEverywhere
      : category == StudentCategory.learningDifficulties;

  /// Mild cognitive: every action button shows a permanent caption under it
  /// explaining what it does (not a hover/long-press tooltip — always
  /// visible).
  bool get showsPermanentTooltips => directives != null
      ? directives!.categoryLayer.confirmAfterEveryStep
      : category == StudentCategory.mildCognitive;

  /// Communication/language: deaf mode only gets a "صياغة رسالة للأستاذ"
  /// button (compose a polite message to the lecturer via Gemini).
  bool get showsMessageAssistant => directives != null
      ? directives!.categoryLayer.readyMadePhrasesForFacultyMessaging.isNotEmpty
      : category == StudentCategory.communicationLanguage;

  /// Behavioral/emotional: sharp failure wording is replaced with a
  /// reassuring phrase (see AppMessages.soften in lib/theme.dart).
  bool get softensErrorMessages => directives != null
      ? directives!.categoryLayer.hidesFailureWording
      : category == StudentCategory.behavioralEmotional;

  // ── Per-mode concrete values (platform integration) ───────────────────
  // These used to be computed by local switch-on-supportLevel statements
  // inside each mode widget/action; relocated here so each call site reads
  // a single getter that prefers the platform's directives when present,
  // falling back to the exact same switch as before otherwise.

  /// Deaf mode: minimum live-transcript font size. Was
  /// `_levelDefaultFontSize` in deaf_mode_transcription_widget.dart.
  double get deafModeFontSize => directives != null
      ? directives!.deafMode.defaultFontSize
      : switch (supportLevel) {
          SupportLevel.light => 16.0,
          SupportLevel.moderate => 18.0,
          SupportLevel.intensive => 22.0,
        };

  /// Learning-support mode: suggested default reading font size (the
  /// student can still adjust it afterward via FFAppState.readingFontSize —
  /// this only seeds the initial value).
  double get learningModeFontSize => directives != null
      ? directives!.learningMode.defaultFontSize
      : switch (supportLevel) {
          SupportLevel.light => 14.0,
          SupportLevel.moderate => 18.0,
          SupportLevel.intensive => 22.0,
        };

  /// Physical-assistance mode: quick-contact FAB scale factor. Was the
  /// inline switch at physical_assistance_mode_widget.dart's FAB builder.
  double get physicalModeQuickContactScale => directives != null
      ? directives!.physicalMode.quickContactScale
      : switch (supportLevel) {
          SupportLevel.light => 1.0,
          SupportLevel.moderate => 1.3,
          SupportLevel.intensive => 1.6,
        };

  /// Physical-assistance mode: voice-command listening window, in seconds.
  /// Was read inline in custom_code/actions/listen_for_voice_command.dart.
  int get physicalModeListeningDurationSeconds => directives != null
      ? directives!.physicalMode.listeningDurationSeconds
      : switch (supportLevel) {
          SupportLevel.light => 3,
          SupportLevel.moderate => 5,
          SupportLevel.intensive => 8,
        };

  /// Visual-assistance mode: TTS speech-rate multiplier (1.0 = normal).
  /// Only meaningful once a platform session is loaded — no enum-based
  /// fallback existed for this before (visual mode didn't previously read
  /// support level for TTS speed at all).
  double get visualModeSpeechRateMultiplier =>
      directives?.visualMode.speechRateMultiplier ?? 1.0;

  StudentProfile copyWith({
    StudentCategory? category,
    SupportLevel? supportLevel,
    AdaptationDirectives? directives,
    List<String>? enabledTools,
  }) =>
      StudentProfile(
        category: category ?? this.category,
        supportLevel: supportLevel ?? this.supportLevel,
        directives: directives ?? this.directives,
        enabledTools: enabledTools ?? this.enabledTools,
      );

  @override
  String toString() =>
      'StudentProfile(category: ${category.name}, supportLevel: ${supportLevel.name})';
}
