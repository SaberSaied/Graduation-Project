import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/storage/local_cache.dart';
import 'firebase_options.dart';
import 'app.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialize Firebase
    if (Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp();
    } else if (!Platform.isLinux && !Platform.isWindows) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue running the app even if Firebase fails
  }

  try {
    // Initialize Hive for offline caching
    await LocalCache.init();
  } catch (e) {
    debugPrint('LocalCache initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: FinanceApp(),
    ),
  );
}
