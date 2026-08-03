import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadow/services/adaptive_prompts.dart';
import 'package:shadow/services/app_prefs.dart';
import 'package:shadow/student/student_profile.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const profile = StudentProfile(
    category: StudentCategory.learningDifficulties,
    supportLevel: SupportLevel.moderate,
  );

  test('buildVisionPrompt is Arabic by default', () async {
    await AppPrefs.getAppLanguage(); // populate sync cache with default
    final prompt = buildVisionPrompt(profile);
    expect(prompt.contains('أنت "شادو"'), true);
    expect(prompt.contains('لا تكشف للطالب تصنيفه ولا مستوى دعمه'), true);
  });

  test('buildVisionPrompt switches to English when app language is en', () async {
    await AppPrefs.setAppLanguage('en');
    final prompt = buildVisionPrompt(profile);
    expect(prompt.contains('You are "Shadow"'), true);
    expect(prompt.contains("Never reveal the student's classification"), true);
    expect(prompt.contains('صعوبات التعلم'), false); // no Arabic leaked in
  });

  test('buildLearningPrompt switches to English and substitutes the action label', () async {
    await AppPrefs.setAppLanguage('en');
    final prompt = buildLearningPrompt(profile, LearningAction.simplify);
    expect(prompt.contains('Requested action: Simplify'), true);
    expect(prompt.contains('Never do the assignment for the student'), true);
  });

  test('switching back to ar restores the Arabic prompt', () async {
    await AppPrefs.setAppLanguage('en');
    await AppPrefs.setAppLanguage('ar');
    final prompt = buildLearningPrompt(profile, LearningAction.summarize);
    expect(prompt.contains('الإجراء المطلوب: تلخيص'), true);
  });
}
