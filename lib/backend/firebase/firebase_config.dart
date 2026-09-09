import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  // Firebase is unused by app code (see docs/AUDIT.md) and not configured
  // for the current package (sa.isleaders.shadow) on any platform — the
  // google-services Gradle plugin is disabled on Android, and the previous
  // web branch here pointed at a stale, unrelated Firebase project
  // ("uni-access-4h4y54") left over from before this app was renamed/
  // rescoped. Removed that hardcoded project config entirely rather than
  // keep shipping a committed identifier for a project this app doesn't
  // use. Guarded so a missing config on any platform cannot crash startup.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('initFirebase skipped (Firebase unused / not configured): $e');
  }
}
