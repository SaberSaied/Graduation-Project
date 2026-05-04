import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // For simplicity, returning the same options across platforms.
    // This allows the app to run on Chrome/Linux without needing separate Firebase apps configured.
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCM_p3dRSEuc-8wS1KKK1D5v0UcVEDSJ4Q",
    appId: "1:452414717624:android:399c7eeb05b00a86ad7e4d",
    messagingSenderId: "452414717624",
    projectId: "finance-app-56182",
    storageBucket: "finance-app-56182.firebasestorage.app",
  );
}
