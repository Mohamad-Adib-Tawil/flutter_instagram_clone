// lib/data/firebase_service/firebase_auth.dart
// DEPRECATED: This file is retained for reference only.
// Authentication has been migrated to Supabase Auth via lib/core/auth/auth_service.dart
// This file is no longer imported or used anywhere in the application.
// It can be safely deleted after verification.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:halalgram/data/firebase_service/firestor.dart';
import 'package:halalgram/data/firebase_service/storage.dart';

import 'package:halalgram/util/exeption.dart';

@Deprecated('Use AuthService from lib/core/auth/auth_service.dart instead')
class Authentication {
  FirebaseAuth _auth = FirebaseAuth.instance;

  @Deprecated('Use AuthService.instance.signIn()')
  Future<void> Login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
    } on FirebaseException catch (e) {
      throw AppException(e.message.toString());
    }
  }

  @Deprecated('Use AuthService.instance.signUp() + SupabaseProfileService')
  Future<void> Signup({
    required String email,
    required String password,
    required String passwordConfirme,
    required String username,
    required String bio,
    required File profile,
  }) async {
    String URL;
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          username.isNotEmpty &&
          bio.isNotEmpty) {
        if (password == passwordConfirme) {
          // create user with email and password
          await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
          // upload profile image on storage

          if (profile != File('')) {
            URL =
                await StorageMethod().uploadImageToStorage('Profile', profile);
          } else {
            URL = '';
          }

          // get information with firestor

          await Firebase_Firestor().CreateUser(
            email: email,
            username: username,
            bio: bio,
            profile: URL == ''
                ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
                : URL,
          );
        } else {
          throw AppException('password and confirm password should be same');
        }
      } else {
        throw AppException('enter all the fields');
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message.toString());
    }
  }
}
