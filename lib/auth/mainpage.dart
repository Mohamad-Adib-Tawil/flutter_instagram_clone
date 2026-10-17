// lib/auth/mainpage.dart
// Root authentication gate using Supabase Auth

import 'package:flutter/material.dart';
import 'package:halalgram/auth/auth_screen.dart';
import 'package:halalgram/core/auth/auth_service.dart';
import 'package:halalgram/widgets/navigation.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AuthSessionState>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          // Show loading while initial session is being restored
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == AuthSessionState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == AuthSessionState.authenticated) {
            return const Navigations_Screen();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
