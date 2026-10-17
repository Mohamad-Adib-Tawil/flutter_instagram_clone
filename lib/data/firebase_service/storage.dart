// lib/data/firebase_service/storage.dart
// Firebase Storage upload using Supabase Auth for user identity

import 'dart:io';

import 'package:flutter_instagram_clone/core/auth/auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImageToStorage(String name, File file) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    final uid = _uuid.v4();
    Reference ref = _storage.ref().child(name).child(userId).child(uid);

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
