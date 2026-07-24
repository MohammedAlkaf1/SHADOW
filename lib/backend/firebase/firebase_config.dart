import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  // TEMP-UNBLOCK (2026-07-25): Firebase is not configured for the current
  // package (sa.isleaders.shadow) and is unused by app code (see docs/AUDIT.md).
  // The google-services Gradle plugin is temporarily disabled, so on Android
  // Firebase.initializeApp() has no config and would throw. Guard it so a
  // missing config cannot crash the build/run. TO RESTORE: re-enable the
  // google-services plugin, fix google-services.json, then remove this
  // try/catch to make init failures fatal again.
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
          options: FirebaseOptions(
              apiKey: "AIzaSyAgOeMGThhIkxK79OUhOC1DZpkvJHQ9cfI",
              authDomain: "uni-access-4h4y54.firebaseapp.com",
              projectId: "uni-access-4h4y54",
              storageBucket: "uni-access-4h4y54.firebasestorage.app",
              messagingSenderId: "254021480061",
              appId: "1:254021480061:web:c31764035f9b60519bcb14"));
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('initFirebase skipped (Firebase unused / not configured): $e');
  }
}
