// lib/main.dart
// App entry point - initializes both Firebase (legacy) and Supabase (new)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:halalgram/auth/mainpage.dart';
import 'package:halalgram/core/config/supabase_config.dart';
import 'package:halalgram/firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (preserved for legacy features during migration)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize Supabase (new backend)
  try {
    SupabaseConfig.validateOrThrow();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabasePublishableKey,
    );
    if (kDebugMode) {
      print('✅ Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Supabase initialization skipped: $e');
      print(
          '   Define SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define to enable.');
    }
    // Supabase initialization failure is non-fatal during migration
    // Firebase-backed features continue to work
  }

  runApp(const MyApp());
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
