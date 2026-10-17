// lib/screen/signup.dart
// Signup screen using Supabase Auth

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/core/auth/auth_service.dart';
import 'package:flutter_instagram_clone/core/config/supabase_config.dart';
import 'package:flutter_instagram_clone/data/supabase_service/supabase_profile.dart';
import 'package:flutter_instagram_clone/util/dialog.dart';
import 'package:flutter_instagram_clone/util/exeption.dart';
import 'package:flutter_instagram_clone/util/imagepicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback show;
  SignupScreen(this.show, {super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();
  final passwordConfirme = TextEditingController();
  FocusNode passwordConfirme_F = FocusNode();
  final username = TextEditingController();
  FocusNode username_F = FocusNode();
  final bio = TextEditingController();
  FocusNode bio_F = FocusNode();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    email.dispose();
    password.dispose();
    passwordConfirme.dispose();
    username.dispose();
    bio.dispose();
    email_F.dispose();
    password_F.dispose();
    passwordConfirme_F.dispose();
    username_F.dispose();
    bio_F.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(width: 96.w, height: 10.h),
            Center(
              child: Image.asset('images/logo.jpg'),
            ),
            SizedBox(width: 96.w, height: 70.h),
            InkWell(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 36.r,
                backgroundColor: Colors.grey,
                child: _imageFile == null
                    ? CircleAvatar(
                        radius: 34.r,
                        backgroundImage: AssetImage('images/person.png'),
                        backgroundColor: Colors.grey.shade200,
                      )
                    : CircleAvatar(
                        radius: 34.r,
                        backgroundImage: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ).image,
                        backgroundColor: Colors.grey.shade200,
                      ),
              ),
            ),
            SizedBox(height: 40.h),
            Textfild(email, email_F, 'Email', Icons.email),
            SizedBox(height: 15.h),
            Textfild(username, username_F, 'username', Icons.person),
            SizedBox(height: 15.h),
            Textfild(bio, bio_F, 'bio', Icons.abc),
            SizedBox(height: 15.h),
            Textfild(password, password_F, 'Password', Icons.lock),
            SizedBox(height: 15.h),
            Textfild(passwordConfirme, passwordConfirme_F, 'PasswordConfirme',
                Icons.lock),
            SizedBox(height: 15.h),
            Signup(),
            SizedBox(height: 15.h),
            Have()
          ],
        ),
      ),
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Don't you have an account?  ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              "Login ",
              style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget Signup() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: _isLoading ? null : _handleSignup,
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: _isLoading ? Colors.grey : Colors.black,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 23.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePickerr().uploadImage('gallery');
      if (mounted) {
        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        dialogBuilder(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _handleSignup() async {
    final emailText = email.text.trim();
    final passwordText = password.text;
    final passwordConfirmeText = passwordConfirme.text;
    final usernameText = username.text.trim();
    final bioText = bio.text.trim();

    // Client-side validation (UX only - DB is final authority)
    if (emailText.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (!_isValidEmail(emailText)) {
      _showError('Please enter a valid email address');
      return;
    }
    if (usernameText.isEmpty) {
      _showError('Please enter a username');
      return;
    }
    if (!_isValidUsername(usernameText)) {
      _showError(
          'Username must be 3-30 characters, alphanumeric and underscore only');
      return;
    }
    if (bioText.isEmpty) {
      _showError('Please enter a bio');
      return;
    }
    if (passwordText.isEmpty) {
      _showError('Please enter a password');
      return;
    }
    if (passwordText.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (passwordText != passwordConfirmeText) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Supabase Auth signup with username in metadata
      final signupResult = await AuthService.instance.signUp(
        email: emailText,
        password: passwordText,
        metadata: {'username': usernameText.toLowerCase()},
      );

      if (!signupResult.success) {
        if (mounted) {
          _showError(signupResult.errorMessage ?? 'Sign up failed');
        }
        return;
      }

      // Step 2: Handle email confirmation required
      if (signupResult.emailConfirmationRequired) {
        if (mounted) {
          _showConfirmationRequired();
        }
        return;
      }

      // Step 3: Upload avatar if provided
      String? avatarPath;
      if (_imageFile != null) {
        try {
          avatarPath =
              await SupabaseProfileService.instance.uploadAvatar(_imageFile!);
          if (avatarPath != null && mounted) {
            await SupabaseProfileService.instance.updateAvatarPath(avatarPath);
          }
        } catch (e) {
          // Avatar upload failed but account created - don't destroy account
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Avatar upload failed: $e. You can add it later.')),
            );
          }
        }
      }

      // Step 4: Update bio (username already set via trigger from metadata)
      try {
        await SupabaseProfileService.instance.updateProfile(bio: bioText);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Profile created but bio update failed: $e')),
          );
        }
      }

      // Success - auth state will handle navigation via MainPage
    } on AppException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Sign up failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConfirmationRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Check Your Email'),
        content: const Text(
          'Your account has been created! Please check your email and click the verification link to activate your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to login
              widget.show();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isValidUsername(String username) {
    if (username.length < SupabaseConfig.usernameMinLength ||
        username.length > SupabaseConfig.usernameMaxLength) {
      return false;
    }
    return SupabaseConfig.usernameAllowedChars.hasMatch(username.toLowerCase());
  }

  void _showError(String message) {
    if (mounted) {
      dialogBuilder(context, message);
    }
  }

  Padding Textfild(TextEditingController controll, FocusNode focusNode,
      String typename, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: TextField(
          style: TextStyle(fontSize: 18.sp, color: Colors.black),
          controller: controll,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: typename,
            prefixIcon: Icon(
              icon,
              color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
