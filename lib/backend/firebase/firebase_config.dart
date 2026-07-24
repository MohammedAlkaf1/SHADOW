import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
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
}
