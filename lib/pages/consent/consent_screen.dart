// First-run privacy consent for the AI features. Shown once; the choice is
// stored locally (AppPrefs). Declining keeps every AI feature off until the
// student changes their mind.
//
// AI features send data to third parties:
//   - lecture audio -> Deepgram (speech to text)
//   - images / PDF text -> Google Gemini (description, simplification)
// The lecturer whose voice is captured is also a data subject.

import 'package:flutter/material.dart';

import '/a11y.dart';
import '/theme.dart';
import '/services/app_prefs.dart';

/// Ensures AI consent before running an AI feature. Returns true if the student
/// has accepted (now or previously), false if they declined.
Future<bool> ensureAiConsent(BuildContext context) async {
  final consent = await AppPrefs.getAiConsent();
  if (consent == true) return true;
  if (!context.mounted) return false;
  return showAiConsent(context);
}

/// Shows the consent screen and returns the student's choice.
Future<bool> showAiConsent(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ConsentScreen(),
    ),
  );
  return result ?? false;
}

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // require an explicit choice
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.privacy_tip_outlined,
                              size: 34.0, color: AppColors.onNavy),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'الخصوصية والموافقة',
                          textAlign: TextAlign.end,
                          style: AppText.display(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'تستخدم بعض ميزات شادو خدمات خارجية (أطراف ثالثة) لتشغيل الذكاء الاصطناعي:',
                          textAlign: TextAlign.end,
                          style: AppText.body(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _bullet(
                            'صوت المحاضرة يُرسل إلى خدمة Deepgram لتحويله إلى نص.'),
                        _bullet(
                            'الصور ونصوص ملفات PDF تُرسل إلى خدمة Google Gemini لوصفها وتبسيطها.'),
                        const SizedBox(height: AppSpacing.md),
                        _note(
                          'قد يلتقط تسجيل الصوت صوت المُحاضِر، وهو أيضاً شخص معنيّ بحماية بياناته. استخدم الميزة بما يحترم خصوصيته.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _note(
                          'لا تُرسل أي بيانات طبية أو سجلات إعاقة إلى هذه الخدمات، ولا يُرسل سوى ما تختاره أنت من صوت أو صور أو ملفات.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'إذا لم توافق، تبقى ميزات الذكاء الاصطناعي متوقفة ويمكنك تفعيلها لاحقاً.',
                          textAlign: TextAlign.end,
                          style: AppText.label(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                a11yButton(
                  label: 'أوافق وأتابع',
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.onNavy,
                      minimumSize: const Size.fromHeight(52.0),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius)),
                    ),
                    onPressed: () async {
                      await AppPrefs.setAiConsent(true);
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                    child: Text('أوافق وأتابع',
                        style: AppText.button(color: AppColors.onNavy)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                a11yButton(
                  label: 'لا أوافق، تبقى ميزات الذكاء الاصطناعي متوقفة',
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onCream,
                      minimumSize: const Size.fromHeight(52.0),
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius)),
                    ),
                    onPressed: () async {
                      await AppPrefs.setAiConsent(false);
                      if (context.mounted) Navigator.of(context).pop(false);
                    },
                    child: Text('لا أوافق',
                        style: AppText.button(color: AppColors.onCream)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bullet leads on the right (RTL): dot first, then the text.
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Icon(Icons.circle, size: 7.0, color: AppColors.terracotta),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, textAlign: TextAlign.end, style: AppText.body()),
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          textAlign: TextAlign.end,
          style: AppText.body(color: AppColors.mutedOnCream)),
    );
  }
}
