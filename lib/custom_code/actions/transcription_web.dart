// Web implementation using the speechBridge JS object injected in index.html.
// Only compiled when targeting Flutter Web (dart.library.html is available).

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<void> startPlatformTranscription(
    void Function(String text) onTranscript) async {
  final bridge = js.context['speechBridge'];

  if (bridge == null) {
    onTranscript('خطأ: speechBridge غير موجود في index.html');
    return;
  }

  // ignore: deprecated_member_use
  bridge.callMethod('start', [
    // ignore: deprecated_member_use
    js.allowInterop((String text) => onTranscript(text)),
    // ignore: deprecated_member_use
    js.allowInterop((String error) {
      if (error == 'not_supported') {
        onTranscript('متصفحك لا يدعم Web Speech API. استخدم Chrome أو Edge.');
      } else if (error == 'not-allowed' || error == 'service-not-allowed') {
        onTranscript('يرجى السماح بالوصول إلى الميكروفون في المتصفح.');
      } else {
        onTranscript('خطأ في التعرف على الصوت: $error');
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
