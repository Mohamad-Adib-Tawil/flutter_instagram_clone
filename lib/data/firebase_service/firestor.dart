// lib/data/firebase_service/firestor.dart
// Firestore operations for features not yet migrated to Supabase
// Remaining: reels, comments, likes, follows

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halalgram/core/auth/auth_service.dart';
import 'package:halalgram/data/model/usermodel.dart';
import 'package:halalgram/util/exeption.dart';
import 'package:uuid/uuid.dart';

class Firebase_Firestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String? get _currentUserId => AuthService.instance.currentUserId;

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String bio,
    required String profile,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw AppException('No authenticated user');
    }

    await _firebaseFirestore.collection('users').doc(userId).set({
      'email': email,
      'username': username,
      'bio': bio,
      'profile': profile,
      'followers': [],
      'following': [],
    });
    return true;
  }

  Future<Usermodel> getUser({String? UID}) async {
    try {
      final targetUid = UID ?? _currentUserId;
      if (targetUid == null) {
        throw AppException('No authenticated user');
      }

      final user =
          await _firebaseFirestore.collection('users').doc(targetUid).get();
      final snapuser = user.data()!;
      return Usermodel(
          snapuser['bio'],
          snapuser['email'],
          snapuser['followers'],
          snapuser['following'],
          snapuser['profile'],
          snapuser['username']);
    } on FirebaseException catch (e) {
      throw AppException(e.message.toString());
    }
  }

  Future<bool> CreatReels({
    required String video,
    required String caption,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw AppException('No authenticated user');
    }

    final uid = _uuid.v4();
    final DateTime data = DateTime.now();
    final Usermodel user = await getUser();
    await _firebaseFirestore.collection('reels').doc(uid).set({
      'reelsvideo': video,
      'username': user.username,
      'profileImage': user.profile,
      'caption': caption,
      'uid': userId,
      'postId': uid,
      'like': [],
      'time': data
    });
    return true;
  }

  Future<bool> Comments({
    required String comment,
    required String type,
    required String uidd,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw AppException('No authenticated user');
    }

    final uid = _uuid.v4();
    final Usermodel user = await getUser();
    await _firebaseFirestore
        .collection(type)
        .doc(uidd)
        .collection('comments')
        .doc(uid)
        .set({
      'comment': comment,
      'username': user.username,
      'profileImage': user.profile,
      'CommentUid': uid,
    });
    return true;
  }

  Future<String> like({
    required List like,
    required String type,
    required String uid,
    required String postId,
  }) async {
    String res = 'some error';
    try {
      if (like.contains(uid)) {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayRemove([uid])
        });
      } else {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } on Exception catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> flollow({
    required String uid,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw AppException('No authenticated user');
    }

    DocumentSnapshot snap =
        await _firebaseFirestore.collection('users').doc(currentUserId).get();
    List following = (snap.data()! as dynamic)['following'];
    try {
      if (following.contains(uid)) {
        _firebaseFirestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayRemove([uid])
        });
        await _firebaseFirestore.collection('users').doc(uid).update({
          'followers': FieldValue.arrayRemove([currentUserId])
        });
      } else {
        _firebaseFirestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayUnion([uid])
        });
        _firebaseFirestore.collection('users').doc(uid).update({
          'followers': FieldValue.arrayUnion([currentUserId])
        });
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }
}
