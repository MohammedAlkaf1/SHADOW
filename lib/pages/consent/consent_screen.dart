// First-run privacy consent for the AI features. Shown once; the choice is
// stored locally (AppPrefs). Declining keeps every AI feature off until the
// student changes their mind.
//
// AI features send data to third parties:
//   - lecture audio -> Deepgram (speech to text)
//   - images / PDF text -> OpenAI (description, simplification)
// The lecturer whose voice is captured is also a data subject.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false, // require an explicit choice
        child: Scaffold(
          backgroundColor: theme.primaryBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 8.0),
                          Icon(Icons.privacy_tip_outlined,
                              size: 44.0, color: theme.primary),
                          const SizedBox(height: 16.0),
                          Text(
                            'الخصوصية والموافقة',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.cairo(
                                fontSize: 24.0, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'تستخدم بعض ميزات شادو خدمات خارجية (أطراف ثالثة) لتشغيل الذكاء الاصطناعي:',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.cairo(fontSize: 16.0, height: 1.6),
                          ),
                          const SizedBox(height: 12.0),
                          _bullet(context,
                              'صوت المحاضرة يُرسل إلى خدمة Deepgram لتحويله إلى نص.'),
                          _bullet(context,
                              'الصور ونصوص ملفات PDF تُرسل إلى خدمة OpenAI لوصفها وتبسيطها.'),
                          const SizedBox(height: 16.0),
                          _note(
                            context,
                            'قد يلتقط تسجيل الصوت صوت المُحاضِر، وهو أيضاً شخص معنيّ بحماية بياناته. استخدم الميزة بما يحترم خصوصيته.',
                          ),
                          const SizedBox(height: 12.0),
                          _note(
                            context,
                            'لا تُرسل أي بيانات طبية أو سجلات إعاقة إلى هذه الخدمات، ولا يُرسل سوى ما تختاره أنت من صوت أو صور أو ملفات.',
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'إذا لم توافق، تبقى ميزات الذكاء الاصطناعي متوقفة ويمكنك تفعيلها لاحقاً.',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.cairo(
                                fontSize: 14.0,
                                color: theme.secondaryText,
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  a11yButton(
                    label: 'أوافق وأتابع',
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        minimumSize: const Size.fromHeight(52.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0)),
                      ),
                      onPressed: () async {
                        await AppPrefs.setAiConsent(true);
                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                      child: Text('أوافق وأتابع',
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16.0)),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  a11yButton(
                    label: 'لا أوافق، تبقى ميزات الذكاء الاصطناعي متوقفة',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryText,
                        minimumSize: const Size.fromHeight(52.0),
                        side: BorderSide(color: theme.alternate, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0)),
                      ),
                      onPressed: () async {
                        await AppPrefs.setAiConsent(false);
                        if (context.mounted) Navigator.of(context).pop(false);
                      },
                      child: Text('لا أوافق',
                          style: GoogleFonts.cairo(fontSize: 16.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(text,
                textAlign: TextAlign.end,
                style: GoogleFonts.cairo(fontSize: 15.0, height: 1.6)),
          ),
          const SizedBox(width: 8.0),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(Icons.circle,
                size: 7.0, color: FlutterFlowTheme.of(context).primary),
          ),
        ],
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Text(text,
          textAlign: TextAlign.end,
          style: GoogleFonts.cairo(fontSize: 14.0, height: 1.6)),
    );
  }
}
