// Dart mirror of the platform's `AdaptationDirectives` JSON shape
// (D:\Shadow\platform\src\lib\adaptation.ts, documented in
// D:\Shadow\platform\docs\API.md). Hand-written (no json_serializable in
// this project — matches the existing plain-Dart-class convention), plain
// data classes with `fromJson` factories only; no business logic here.
//
// These are OPAQUE values by design: font sizes, text-style tags, alert
// thresholds — never the raw category/support-level that produced them.
// The platform computes them server-side specifically so this app never
// has to hold (or derive UI from) a student's classification directly.

class AdaptationDirectives {
  const AdaptationDirectives({
    required this.deafMode,
    required this.visualMode,
    required this.learningMode,
    required this.physicalMode,
    required this.categoryLayer,
  });

  final DeafModeDirectives deafMode;
  final VisualModeDirectives visualMode;
  final LearningModeDirectives learningMode;
  final PhysicalModeDirectives physicalMode;
  final CategoryLayerDirectives categoryLayer;

  factory AdaptationDirectives.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as Map<String, dynamic>? ?? const {};
    return AdaptationDirectives(
      deafMode: DeafModeDirectives.fromJson(
          mode['deafMode'] as Map<String, dynamic>? ?? const {}),
      visualMode: VisualModeDirectives.fromJson(
          mode['visualMode'] as Map<String, dynamic>? ?? const {}),
      learningMode: LearningModeDirectives.fromJson(
          mode['learningMode'] as Map<String, dynamic>? ?? const {}),
      physicalMode: PhysicalModeDirectives.fromJson(
          mode['physicalMode'] as Map<String, dynamic>? ?? const {}),
      categoryLayer: CategoryLayerDirectives.fromJson(
          json['categoryLayer'] as Map<String, dynamic>? ?? const {}),
    );
  }

  /// Safe, mildest-tier fallback used before any platform data has ever
  /// been fetched, and offline with no cache — mirrors the platform's own
  /// `defaultAdaptationDirectives()`.
  static const fallback = AdaptationDirectives(
    deafMode: DeafModeDirectives(
      displayedTextStyle: 'continuous_punctuated',
      defaultFontSize: 16,
      hardTermHandling: 'none',
      postLectureOutput: 'full_text',
      mentorAlert: 'none',
    ),
    visualMode: VisualModeDirectives(
      imageDescriptionStyle: 'one_concise_paragraph',
      readAloudSpeed: 'normal',
      followUpQuestion: 'none',
      mentorAlert: 'none',
    ),
    learningMode: LearningModeDirectives(
      summarizeButtonOutput: 'brief_paragraph',
      simplifyButtonOutput: 'light_rephrase',
      reviewQuestionsButtonOutput: 'three_analytical',
      defaultFontSize: 14,
      mentorAlert: 'none',
    ),
    physicalMode: PhysicalModeDirectives(
      voiceCommandHandling: 'execute_directly',
      quickContactButtonSize: 'normal',
      listeningDurationSeconds: 3,
      tolerantOfStutter: false,
      mentorAlert: 'none',
    ),
    categoryLayer: CategoryLayerDirectives.none,
  );
}

class DeafModeDirectives {
  const DeafModeDirectives({
    required this.displayedTextStyle,
    required this.defaultFontSize,
    required this.hardTermHandling,
    required this.postLectureOutput,
    required this.mentorAlert,
  });

  final String displayedTextStyle;
  final double defaultFontSize;
  final String hardTermHandling;
  final String postLectureOutput;
  final String mentorAlert;

  factory DeafModeDirectives.fromJson(Map<String, dynamic> json) =>
      DeafModeDirectives(
        displayedTextStyle:
            json['displayedTextStyle'] as String? ?? 'continuous_punctuated',
        defaultFontSize: (json['defaultFontSize'] as num?)?.toDouble() ?? 16,
        hardTermHandling: json['hardTermHandling'] as String? ?? 'none',
        postLectureOutput: json['postLectureOutput'] as String? ?? 'full_text',
        mentorAlert: json['mentorAlert'] as String? ?? 'none',
      );
}

class VisualModeDirectives {
  const VisualModeDirectives({
    required this.imageDescriptionStyle,
    required this.readAloudSpeed,
    required this.followUpQuestion,
    required this.mentorAlert,
  });

  final String imageDescriptionStyle;
  final String readAloudSpeed;
  final String followUpQuestion;
  final String mentorAlert;

  factory VisualModeDirectives.fromJson(Map<String, dynamic> json) =>
      VisualModeDirectives(
        imageDescriptionStyle:
            json['imageDescriptionStyle'] as String? ?? 'one_concise_paragraph',
        readAloudSpeed: json['readAloudSpeed'] as String? ?? 'normal',
        followUpQuestion: json['followUpQuestion'] as String? ?? 'none',
        mentorAlert: json['mentorAlert'] as String? ?? 'none',
      );

  /// Multiplier to apply to the base TTS speech rate (1.0 = normal).
  double get speechRateMultiplier => switch (readAloudSpeed) {
        'minus_20_percent' => 0.8,
        'minus_40_percent_auto_repeat_on_finish' => 0.6,
        _ => 1.0,
      };

  bool get autoRepeatOnFinish =>
      readAloudSpeed == 'minus_40_percent_auto_repeat_on_finish';
}

class LearningModeDirectives {
  const LearningModeDirectives({
    required this.summarizeButtonOutput,
    required this.simplifyButtonOutput,
    required this.reviewQuestionsButtonOutput,
    required this.defaultFontSize,
    required this.mentorAlert,
  });

  final String summarizeButtonOutput;
  final String simplifyButtonOutput;
  final String reviewQuestionsButtonOutput;
  final double defaultFontSize;
  final String mentorAlert;

  factory LearningModeDirectives.fromJson(Map<String, dynamic> json) =>
      LearningModeDirectives(
        summarizeButtonOutput:
            json['summarizeButtonOutput'] as String? ?? 'brief_paragraph',
        simplifyButtonOutput:
            json['simplifyButtonOutput'] as String? ?? 'light_rephrase',
        reviewQuestionsButtonOutput:
            json['reviewQuestionsButtonOutput'] as String? ?? 'three_analytical',
        defaultFontSize: (json['defaultFontSize'] as num?)?.toDouble() ?? 14,
        mentorAlert: json['mentorAlert'] as String? ?? 'none',
      );
}

class PhysicalModeDirectives {
  const PhysicalModeDirectives({
    required this.voiceCommandHandling,
    required this.quickContactButtonSize,
    required this.listeningDurationSeconds,
    required this.tolerantOfStutter,
    required this.mentorAlert,
  });

  final String voiceCommandHandling;
  final String quickContactButtonSize;
  final int listeningDurationSeconds;
  final bool tolerantOfStutter;
  final String mentorAlert;

  factory PhysicalModeDirectives.fromJson(Map<String, dynamic> json) =>
      PhysicalModeDirectives(
        voiceCommandHandling:
            json['voiceCommandHandling'] as String? ?? 'execute_directly',
        quickContactButtonSize:
            json['quickContactButtonSize'] as String? ?? 'normal',
        listeningDurationSeconds:
            (json['listeningDurationSeconds'] as num?)?.toInt() ?? 3,
        tolerantOfStutter: json['tolerantOfStutter'] as bool? ?? false,
        mentorAlert: json['mentorAlert'] as String? ?? 'none',
      );

  /// Quick-contact FAB scale factor — mirrors the size tiers described in
  /// the plan doc (normal / large / extra-large with direct home access).
  double get quickContactScale => switch (quickContactButtonSize) {
        'large' => 1.3,
        'extra_large_with_direct_home_screen_access' => 1.6,
        _ => 1.0,
      };
}

class CategoryLayerDirectives {
  const CategoryLayerDirectives({
    this.reducesNotifications = false,
    this.hidesNonEssentialVisualElements = false,
    this.maxOneInteractiveElementPerScreen = false,
    this.calmColorPalette = false,
    this.autoSummarizesEverywhere = false,
    this.repeatsIdeasTwoWays = false,
    this.ttsSupportEverywhere = false,
    this.oneStepAtATime = false,
    this.confirmAfterEveryStep = false,
    this.dailyLifeExamplesInsteadOfDefinitions = false,
    this.simplerUiLanguage = false,
    this.autoRephrasing = false,
    this.readyMadePhrasesForFacultyMessaging = const [],
    this.reassuringTone = false,
    this.hidesFailureWording = false,
    this.gentleAlternativePhrasing = false,
    this.suppressesRepeatedAnnoyingAlerts = false,
  });

  // Neurodevelopmental (autism / ADHD)
  final bool reducesNotifications;
  final bool hidesNonEssentialVisualElements;
  final bool maxOneInteractiveElementPerScreen;
  final bool calmColorPalette;
  // Learning difficulties
  final bool autoSummarizesEverywhere;
  final bool repeatsIdeasTwoWays;
  final bool ttsSupportEverywhere;
  // Mild cognitive disabilities
  final bool oneStepAtATime;
  final bool confirmAfterEveryStep;
  final bool dailyLifeExamplesInsteadOfDefinitions;
  // Communication & language disorders
  final bool simplerUiLanguage;
  final bool autoRephrasing;
  final List<String> readyMadePhrasesForFacultyMessaging;
  // Behavioral & emotional disorders
  final bool reassuringTone;
  final bool hidesFailureWording;
  final bool gentleAlternativePhrasing;
  final bool suppressesRepeatedAnnoyingAlerts;

  static const none = CategoryLayerDirectives();

  factory CategoryLayerDirectives.fromJson(Map<String, dynamic> json) =>
      CategoryLayerDirectives(
        reducesNotifications: json['reducesNotifications'] as bool? ?? false,
        hidesNonEssentialVisualElements:
            json['hidesNonEssentialVisualElements'] as bool? ?? false,
        maxOneInteractiveElementPerScreen:
            json['maxOneInteractiveElementPerScreen'] as bool? ?? false,
        calmColorPalette: json['calmColorPalette'] as bool? ?? false,
        autoSummarizesEverywhere:
            json['autoSummarizesEverywhere'] as bool? ?? false,
        repeatsIdeasTwoWays: json['repeatsIdeasTwoWays'] as bool? ?? false,
        ttsSupportEverywhere: json['ttsSupportEverywhere'] as bool? ?? false,
        oneStepAtATime: json['oneStepAtATime'] as bool? ?? false,
        confirmAfterEveryStep: json['confirmAfterEveryStep'] as bool? ?? false,
        dailyLifeExamplesInsteadOfDefinitions:
            json['dailyLifeExamplesInsteadOfDefinitions'] as bool? ?? false,
        simplerUiLanguage: json['simplerUiLanguage'] as bool? ?? false,
        autoRephrasing: json['autoRephrasing'] as bool? ?? false,
        readyMadePhrasesForFacultyMessaging:
            (json['readyMadePhrasesForFacultyMessaging'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
        reassuringTone: json['reassuringTone'] as bool? ?? false,
        hidesFailureWording: json['hidesFailureWording'] as bool? ?? false,
        gentleAlternativePhrasing:
            json['gentleAlternativePhrasing'] as bool? ?? false,
        suppressesRepeatedAnnoyingAlerts:
            json['suppressesRepeatedAnnoyingAlerts'] as bool? ?? false,
      );
}
