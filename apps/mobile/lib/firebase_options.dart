import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

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
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '[GCP_API_KEY]'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:452414717624:android:399c7eeb05b00a86ad7e4d'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '452414717624'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'finance-app-56182'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'finance-app-56182.firebasestorage.app'),
  );
}
