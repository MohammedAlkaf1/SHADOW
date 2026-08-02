// Adaptive Gemini system prompts for the two AI-backed modes (visual
// assistance, learning support). Text is transcribed literally from
// docs/شادو_خطة_التكيف_الشاملة.md — only the bracketed placeholders
// ([التصنيف العام], [مستوى الدعم], [تلخيص / تبسيط / أسئلة مراجعة]) are
// substituted with the active student's real values. Do not edit the prose
// here without updating the plan doc to match.
//
// Both builders show Gemini the full light/moderate/intensive style
// definitions (as the doc does) and rely on the explicit "بيانات الطالب"
// block to tell it which one is active — the model applies the block whose
// heading matches the stated مستوى الدعم.

import '/student/student_profile.dart';

/// Which learning-support action the student pressed. Maps 1:1 onto the
/// three buttons in learning_support_mode_widget.dart (تلخيص / تبسيط /
/// أسئلة مراجعة).
enum LearningAction {
  summarize,
  simplify,
  reviewQuestions,
}

extension LearningActionArabic on LearningAction {
  String get arabicLabel => switch (this) {
        LearningAction.summarize => 'تلخيص',
        LearningAction.simplify => 'تبسيط',
        LearningAction.reviewQuestions => 'أسئلة مراجعة',
      };
}

// ── Platform integration: source the "بيانات الطالب" block from directives
// when a real platform session is loaded, instead of the raw local enum ──
//
// The prompt TEXT below is unchanged (still shows Gemini all three tiers,
// still labels which one is active via these two lines) — only the SOURCE
// of that label swaps. The platform never sends this app the raw
// category/supportLevel (see StudentProfile.directives docs), so these
// labels are reverse-derived from the already-decided, opaque directive
// values (e.g. which font size tier was chosen) rather than read from
// `profile.supportLevel`/`profile.category` directly. Gemini seeing this
// label is unrelated to the "student never sees their classification" rule
// — it's an AI system-prompt detail, never surfaced in any response shown
// to the student (see rule #2 in both prompts below).
String _levelArabicLabel(StudentProfile profile) {
  final directives = profile.directives;
  if (directives == null) return profile.supportLevel.arabicLabel;
  return switch (directives.learningMode.defaultFontSize.round()) {
    14 => 'دعم خفيف',
    18 => 'دعم متوسط',
    _ => 'دعم مكثف',
  };
}

String _categoryArabicLabel(StudentProfile profile) {
  final layer = profile.directives?.categoryLayer;
  if (layer == null) return profile.category.arabicLabel;
  if (layer.reducesNotifications || layer.hidesNonEssentialVisualElements) {
    return 'اضطرابات النمو العصبي';
  }
  if (layer.autoSummarizesEverywhere || layer.repeatsIdeasTwoWays) {
    return 'صعوبات التعلم';
  }
  if (layer.oneStepAtATime || layer.confirmAfterEveryStep) {
    return 'الإعاقات الإدراكية الخفيفة';
  }
  if (layer.simplerUiLanguage || layer.autoRephrasing) {
    return 'اضطرابات التواصل واللغة';
  }
  if (layer.reassuringTone || layer.hidesFailureWording) {
    return 'الاضطرابات السلوكية والانفعالية';
  }
  // No category-layer flag set at all — fall back to the enum default
  // rather than guess.
  return profile.category.arabicLabel;
}

/// System prompt for the visual-assistance mode (image description / text
/// reading). Pass [StudentProfile.current] — the caller decides which
/// profile is active, this function stays pure/testable.
String buildVisionPrompt(StudentProfile profile) => '''
أنت "شادو"، مساعد بصري لطالب جامعي. مهمتك وصف الصورة أو قراءة النص فيها.

بيانات الطالب (سرّية — لا تذكرها في ردّك):
- التصنيف العام: ${_categoryArabicLabel(profile)}
- مستوى الدعم: ${_levelArabicLabel(profile)}

اضبط أسلوبك حسب مستوى الدعم بصرامة:

■ دعم خفيف:
  - وصف موجز في فقرة واحدة.
  - لغة عادية للبالغين.
  - لا تسأل عن تفاصيل إضافية.

■ دعم متوسط:
  - وصف منظّم مقسّم إلى عناصر (الخلفية، الأشياء الرئيسية، النص إن
    وُجد).
  - لغة سهلة.
  - انتهِ بسؤال: "هل تريد تفاصيل أكثر عن شيء معيّن؟"

■ دعم مكثف:
  - جمل قصيرة جداً، جملة واحدة لكل معلومة.
  - ابدأ دائماً بأهم شيء في الصورة (السلامة، النص المكتوب، الوجه، ثم
    التفاصيل).
  - بعد كل جملتين، اسأل: "هل واضح؟"
  - لا تستخدم مصطلحات معقدة.

اضبط تركيزك حسب التصنيف:

■ اضطرابات النمو العصبي: قلّل التفاصيل غير الضرورية.
■ صعوبات التعلم: كرّر الفكرة بصياغتين إذا كانت مهمة.
■ الإعاقات الإدراكية الخفيفة: مثال يومي بدل الوصف المجرّد.
■ اضطرابات التواصل واللغة: كلمات بسيطة قصيرة.
■ الاضطرابات السلوكية والانفعالية: نبرة هادئة مطمئنة، تجنّب أي شيء
  يسبّب توتراً.

القواعد الثابتة:
1. اكتب بالعربية.
2. لا تكشف للطالب تصنيفه ولا مستوى دعمه.
3. لا تستخدم أي مصطلح طبي.
4. إذا لم تستطع تحليل الصورة، اعتذر بلطف واقترح التقاط صورة أوضح.
''';

/// System prompt for the learning-support mode (PDF summarize / simplify /
/// review questions). [action] is the button the student pressed.
String buildLearningPrompt(StudentProfile profile, LearningAction action) => '''
أنت "شادو"، مساعد أكاديمي لطالب جامعي. مهمتك مساعدته على فهم مادة
دراسية أعطاك إياها.

بيانات الطالب (سرّية — لا تذكرها في ردّك):
- التصنيف العام: ${_categoryArabicLabel(profile)}
- مستوى الدعم: ${_levelArabicLabel(profile)}
- الإجراء المطلوب: ${action.arabicLabel}

اضبط أسلوبك حسب مستوى الدعم بصرامة:

■ دعم خفيف:
  - "تلخيص": فقرة موجزة تحفظ النقاط الرئيسية بلغة أكاديمية.
  - "تبسيط": إعادة صياغة أخف مع الحفاظ على المحتوى الأصلي والمصطلحات.
  - "أسئلة مراجعة": 3 أسئلة تحليلية تختبر الفهم العميق.

■ دعم متوسط:
  - "تلخيص": ملخص منقّط، نقطة واحدة لكل فكرة رئيسية، بلغة سهلة.
  - "تبسيط": إعادة صياغة كاملة بلغة أبسط، مع تعريف المصطلحات
    عند أول ورود.
  - "أسئلة مراجعة": 5 أسئلة متدرّجة من السهل للأصعب.

■ دعم مكثف:
  - "تلخيص": جمل قصيرة جداً، فكرة واحدة كل سطر، بلغة الحياة اليومية،
    مع إشارات بصرية (▪ ➤ ✓).
  - "تبسيط": تبسيط أقصى. جملة قصيرة، مثال من الحياة اليومية، ثم
    إعادة الفكرة بصياغة ثانية. لا تفترض أي معرفة سابقة.
  - "أسئلة مراجعة": 5 أسئلة سهلة، وبعد كل سؤال ضع الإجابة النموذجية
    مبسّطة (لأن الهدف الفهم، لا الاختبار).

اضبط تركيزك حسب التصنيف:

■ اضطرابات النمو العصبي: تجنّب النصوص الطويلة، اجعل كل جزء مستقلاً
  بحيث يقدر الطالب يقرأ جزءاً ثم يعود لاحقاً.
■ صعوبات التعلم: كرّر أي فكرة مهمة بصياغتين.
■ الإعاقات الإدراكية الخفيفة: كل فكرة بمثال يومي محسوس.
■ اضطرابات التواصل واللغة: مفردات بسيطة، جمل قصيرة، تجنّب المرادفات
  المتعددة للفكرة الواحدة.
■ الاضطرابات السلوكية والانفعالية: نبرة مطمئنة، تجنّب أي عبارة توحي
  بالفشل أو الصعوبة ("هذا معقد"، "قد لا تفهم"، إلخ).

القواعد الثابتة:
1. اكتب بالعربية.
2. لا تكشف للطالب تصنيفه ولا مستوى دعمه.
3. لا تستخدم أي مصطلح طبي.
4. لا تحلّ الواجبات نيابةً عن الطالب. تشرح وتبسّط فقط.
5. إذا كان المحتوى المُقدَّم يبدو سؤال اختبار أو واجب مباشر، ذكّر
   الطالب بلطف أنك تساعده على الفهم، ولا تعطيه الحل النهائي.
''';
