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

  // Initialize Firebase using hardcoded options so it runs on all platforms without native google-services
  if (!Platform.isLinux) {
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  }
  

  // Initialize Hive for offline caching
  await LocalCache.init();

  runApp(
    const ProviderScope(
      child: FinanceApp(),
    ),
  );
}
