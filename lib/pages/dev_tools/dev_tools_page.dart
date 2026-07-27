// Developer-only screen: lets you switch the active StudentProfile
// (category + support level) live, without restarting the app, so later
// phases (Gemini prompt adaptation, mode-UI adaptation) can be tested
// against every combination. Never reachable in a release build — both the
// entry point and this screen itself are gated behind kDebugMode.
//
// This is NOT part of the four student-facing modes; it is a testing tool
// for the person building the adaptation engine.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/a11y.dart';
import '/theme.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';

const Map<StudentCategory, String> _categoryLabels = {
  StudentCategory.neurodevelopmental: 'اضطرابات النمو العصبي',
  StudentCategory.learningDifficulties: 'صعوبات التعلم',
  StudentCategory.mildCognitive: 'الإعاقات الإدراكية الخفيفة',
  StudentCategory.communicationLanguage: 'اضطرابات التواصل واللغة',
  StudentCategory.behavioralEmotional: 'الاضطرابات السلوكية والانفعالية',
};

const Map<SupportLevel, String> _supportLevelLabels = {
  SupportLevel.light: 'دعم خفيف',
  SupportLevel.moderate: 'دعم متوسط',
  SupportLevel.intensive: 'دعم مكثف',
};

class DevToolsPage extends StatelessWidget {
  const DevToolsPage({super.key});

  static String routeName = 'DevTools';
  static String routePath = '/devTools';

  @override
  Widget build(BuildContext context) {
    // Defensive: even though the only entry point is itself debug-gated,
    // never render real content here in a release build.
    if (!kDebugMode) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final provider = context.watch<StudentProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.onCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: a11yButton(
          label: 'رجوع',
          child: IconButton(
            icon: appBackIcon(context),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text('أدوات المطوّر', style: AppText.title()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _banner(),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('التصنيف العام (Category)'),
          const SizedBox(height: AppSpacing.sm),
          _card(
            child: Column(
              children: StudentCategory.values
                  .map((c) => _categoryTile(context, provider, c))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('مستوى الدعم (Support level)'),
          const SizedBox(height: AppSpacing.sm),
          _card(
            child: Column(
              children: SupportLevel.values
                  .map((l) => _supportLevelTile(context, provider, l))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'يعيد --dart-define=STUDENT_CATEGORY=... و '
            '--dart-define=STUDENT_SUPPORT_LEVEL=... ضبط القيمة الافتراضية '
            'عند تشغيل التطبيق فقط؛ التبديل هنا مؤقت لهذه الجلسة.',
            textAlign: TextAlign.end,
            style: AppText.label(),
          ),
        ],
      ),
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.science_outlined, color: AppColors.terracotta),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'أدوات اختبار داخلية — لا تظهر في نسخة الإصدار (release).',
                textAlign: TextAlign.end,
                style: AppText.body(color: AppColors.onNavy),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) =>
      Text(text, textAlign: TextAlign.end, style: AppText.cardTitle(color: AppColors.onCream));

  Widget _card({required Widget child}) => Container(
        decoration: AppDecor.creamCard(),
        child: child,
      );

  // Bare RadioListTile (no a11yButton wrap): RadioListTile already exposes
  // correct radio-button semantics on its own, which a11yButton's
  // Semantics(button: true) would override with a plain "button" role.
  Widget _categoryTile(
    BuildContext context,
    StudentProfileProvider provider,
    StudentCategory value,
  ) {
    return RadioListTile<StudentCategory>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: provider.category,
      activeColor: AppColors.terracotta,
      // ignore: deprecated_member_use
      onChanged: (v) {
        if (v != null) provider.setCategory(v);
      },
      title: Text(
        _categoryLabels[value]!,
        textAlign: TextAlign.end,
        style: AppText.body(),
      ),
    );
  }

  Widget _supportLevelTile(
    BuildContext context,
    StudentProfileProvider provider,
    SupportLevel value,
  ) {
    return RadioListTile<SupportLevel>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: provider.supportLevel,
      activeColor: AppColors.terracotta,
      // ignore: deprecated_member_use
      onChanged: (v) {
        if (v != null) provider.setSupportLevel(v);
      },
      title: Text(
        _supportLevelLabels[value]!,
        textAlign: TextAlign.end,
        style: AppText.body(),
      ),
    );
  }
}
