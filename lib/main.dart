// lib/main.dart
// App entry point - initializes both Firebase (legacy) and Supabase (new)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:halalgram/auth/mainpage.dart';
import 'package:halalgram/core/config/supabase_config.dart';
import 'package:halalgram/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    SupabaseConfig.validateOrThrow();
    // Firebase still supports legacy features during the migration.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabasePublishableKey,
    );
  } on Exception {
    runApp(const _StartupFailureApp());
    return;
  } on StateError {
    runApp(const _StartupFailureApp());
    return;
  }

  runApp(const MyApp());
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    // This screen must work before backend and app localization initialization.
    final isArabic =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: Text(
              isArabic ? 'تعذّر بدء حلالكرام.' : 'Halalgram could not start.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenUtilInit(designSize: Size(375, 812), child: MainPage()),
    );
  }
}
