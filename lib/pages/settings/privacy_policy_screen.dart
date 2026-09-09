// Privacy policy screen — accessible from Settings. Content is written
// conservatively, describing only what this app and its companion platform
// actually collect/process, based on the real code paths (platform_client,
// ai_client, app_prefs). See docs/PRIVACY_POLICY_SOURCE.md for the
// justification behind each claim below.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static String routeName = 'PrivacyPolicy';
  static String routePath = '/settings/privacy-policy';

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text('settings.privacyPolicy'.tr(),
            style: AppText.custom(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onCream)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            isArabic ? _arabicPolicy : _englishPolicy,
            textAlign: TextAlign.start,
            style: AppText.custom(
                fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.onCream),
          ),
        ),
      ),
    );
  }
}

const String _englishPolicy = '''
Shadow — Privacy Policy

Last updated: 2026-09-09

This screen describes what Shadow ("the app") and its companion platform
actually collect and process. It is written to reflect the current
implementation, not a generic template.

1. Data we collect
• Account information: the email address you sign in with, and an
  authentication session (a short-lived access token kept only in memory,
  and — only if you enable "remember me" — a longer-lived refresh token
  stored in your device's secure keystore, never in plain text).
• Profile/adaptation data: accessibility preferences and support settings
  associated with your account, fetched from the platform and cached
  on-device so the app keeps working offline.
• Usage events: small, non-identifying interaction records (e.g. which
  accessibility mode was used) queued on-device and sent to the platform in
  batches. This never includes transcript text, audio, or documents.
• Locally-saved settings: language, font size, theme, a quick-contact phone
  number if you set one, and transcript retention preference. These stay
  on your device.

2. AI / third-party processing
Certain accessibility features (real-time speech-to-text for the
deaf/hard-of-hearing mode, and image/document understanding for the
learning-support mode) send audio or images you provide to third-party AI
providers (Deepgram for speech-to-text, Google Gemini for vision/text) to
generate a response. This only happens when you actively use those
features, and you are asked to consent before first use. These providers
process the content under their own privacy terms; Shadow does not control
their retention.

3. Storage & retention
• Saved transcripts are stored on-device, with a retention period you
  control in Settings (default 30 days).
• Authentication credentials use platform-appropriate secure storage
  (Android Keystore-backed encrypted storage / iOS Keychain), never plain
  SharedPreferences.
• We do not maintain a separate analytics/tracking SDK in this app.

4. Your rights
• You can sign out at any time, which clears your session and any
  remembered login from the device.
• You can clear saved transcripts and the quick-contact number from
  Settings.
• You can withdraw AI consent; features that require it will stop working
  until you re-consent.
• To request deletion of your platform account/data, contact your
  institution's Shadow platform administrator.

5. Security practices
• All platform API traffic requires HTTPS in production builds — a release
  build refuses to run against a non-HTTPS or development endpoint.
• Access tokens are never persisted to disk; refresh tokens and saved
  credentials use encrypted, OS-level secure storage.
• We do not log passwords, tokens, or API keys.

6. Contact
For privacy questions, contact your institution's Shadow platform
administrator, or the app's maintainers via the repository listed in this
app's README.

Note: this policy describes the app's technical data handling. It is not a
substitute for your institution's own data-protection/legal policy, which
governs the platform account itself.
''';

const String _arabicPolicy = '''
شادو — سياسة الخصوصية

آخر تحديث: 2026-09-09

يوضّح هذا القسم ما يجمعه تطبيق "شادو" والمنصة المرتبطة به فعليًا، بناءً على
التنفيذ الحالي للتطبيق وليس نصًا عامًا.

١. البيانات التي نجمعها
• معلومات الحساب: البريد الإلكتروني الذي تسجّل الدخول به، وجلسة مصادقة (رمز
  وصول قصير الأمد يُحفظ في الذاكرة فقط، ورمز تجديد أطول أمدًا — فقط إن
  فعّلت "تذكرني" — يُحفظ في التخزين الآمن للجهاز، وليس كنص عادي أبدًا).
• بيانات الملف الشخصي والتكيّف: تفضيلات إمكانية الوصول وإعدادات الدعم
  المرتبطة بحسابك، تُجلب من المنصة وتُخزّن محليًا ليستمر عمل التطبيق دون
  اتصال بالإنترنت.
• أحداث الاستخدام: سجلات تفاعل صغيرة وغير مُعرِّفة للهوية (مثل أي وضع
  إمكانية وصول استُخدم) تُجمّع على الجهاز وتُرسل للمنصة على دفعات. لا تشمل
  أبدًا نص النسخ الصوتي أو الصوت أو المستندات.
• الإعدادات المحفوظة محليًا: اللغة، حجم الخط، المظهر، رقم اتصال سريع إن
  حددته، ومدة الاحتفاظ بالنسخ الصوتية. تبقى هذه على جهازك فقط.

٢. الذكاء الاصطناعي ومعالجة الطرف الثالث
بعض ميزات إمكانية الوصول (تحويل الكلام إلى نص الفوري لوضع الصم وضعاف
السمع، وفهم الصور/المستندات لوضع الدعم التعليمي) ترسل الصوت أو الصور التي
تقدمها إلى مزودي ذكاء اصطناعي من طرف ثالث (Deepgram لتحويل الكلام إلى نص،
وGoogle Gemini للرؤية والنص) لإنشاء استجابة. يحدث هذا فقط عند استخدامك
الفعلي لهذه الميزات، وستُسأل عن الموافقة قبل أول استخدام. يعالج هؤلاء
المزودون المحتوى وفق سياسات الخصوصية الخاصة بهم؛ لا يتحكم شادو في مدة
احتفاظهم بالبيانات.

٣. التخزين والاحتفاظ بالبيانات
• تُخزَّن النسخ الصوتية المحفوظة على الجهاز، بمدة احتفاظ تتحكم بها من
  الإعدادات (٣٠ يومًا افتراضيًا).
• تستخدم بيانات المصادقة تخزينًا آمنًا مناسبًا للمنصة (تخزين مشفّر مدعوم من
  Android Keystore أو iOS Keychain)، وليس أبدًا SharedPreferences العادي.
• لا يحتوي هذا التطبيق على أداة تحليلات/تتبع منفصلة.

٤. حقوقك
• يمكنك تسجيل الخروج في أي وقت، مما يمسح جلستك وأي بيانات دخول محفوظة من
  الجهاز.
• يمكنك مسح النسخ الصوتية المحفوظة ورقم الاتصال السريع من الإعدادات.
• يمكنك سحب موافقتك على الذكاء الاصطناعي؛ ستتوقف الميزات التي تتطلبها حتى
  تُوافق مجددًا.
• لطلب حذف حسابك/بياناتك على المنصة، تواصل مع مسؤول منصة شادو في مؤسستك.

٥. ممارسات الأمان
• تتطلب جميع اتصالات واجهة برمجة تطبيقات المنصة HTTPS في إصدارات الإنتاج —
  ترفض نسخة الإصدار العمل مع نقطة نهاية غير HTTPS أو نقطة تطوير.
• لا تُحفظ رموز الوصول على القرص أبدًا؛ تستخدم رموز التجديد وبيانات الدخول
  المحفوظة تخزينًا آمنًا مشفّرًا على مستوى نظام التشغيل.
• لا نسجّل كلمات المرور أو الرموز أو مفاتيح الواجهة البرمجية.

٦. التواصل
لأي استفسارات تتعلق بالخصوصية، تواصل مع مسؤول منصة شادو في مؤسستك، أو مع
فريق صيانة التطبيق عبر المستودع المذكور في ملف README الخاص بالتطبيق.

ملاحظة: تصف هذه السياسة التعامل التقني للتطبيق مع البيانات، وهي ليست بديلاً
عن سياسة حماية البيانات القانونية الخاصة بمؤسستك، والتي تحكم حساب المنصة
نفسه.
''';
