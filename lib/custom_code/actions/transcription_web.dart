// Web implementation using the speechBridge JS object injected in index.html.
// Only compiled when targeting Flutter Web (dart.library.html is available).

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import '/services/app_prefs.dart';

/// Picks Arabic or English for an on-screen status/error string based on the
/// student's app-language setting — this file has no BuildContext to read
/// via easy_localization's `.tr()`, same reasoning as PlatformClient._bi.
String _bi(String ar, String en) => AppPrefs.currentAppLanguage == 'en' ? en : ar;

// [courseKeyterms] is accepted for call-site parity with the mobile
// (Deepgram) implementation but unused here — the browser's Web Speech API
// has no equivalent boosting mechanism.
Future<void> startPlatformTranscription(
    void Function(String text) onTranscript,
    {List<String> courseKeyterms = const []}) async {
  final bridge = js.context['speechBridge'];

  if (bridge == null) {
    onTranscript(_bi(
        'خطأ: speechBridge غير موجود في index.html', 'Error: speechBridge is missing from index.html'));
    return;
  }

  // ignore: deprecated_member_use
  bridge.callMethod('start', [
    // ignore: deprecated_member_use
    js.allowInterop((String text) => onTranscript(text)),
    // ignore: deprecated_member_use
    js.allowInterop((String error) {
      if (error == 'not_supported') {
        onTranscript(_bi('متصفحك لا يدعم Web Speech API. استخدم Chrome أو Edge.',
            'Your browser doesn\'t support the Web Speech API. Use Chrome or Edge.'));
      } else if (error == 'not-allowed' || error == 'service-not-allowed') {
        onTranscript(_bi('يرجى السماح بالوصول إلى الميكروفون في المتصفح.',
            'Please allow microphone access in the browser.'));
      } else {
        onTranscript(_bi('خطأ في التعرف على الصوت: $error', 'Speech recognition error: $error'));
      }
    }),
  ]);
}

void stopPlatformTranscription() {
  // ignore: deprecated_member_use
  js.context['speechBridge']?.callMethod('stop');
}

bool get isPlatformSupported {
  // ignore: deprecated_member_use
  final bridge = js.context['speechBridge'];
  if (bridge == null) return false;
  // ignore: deprecated_member_use
  return bridge.callMethod('isSupported') == true;
}
