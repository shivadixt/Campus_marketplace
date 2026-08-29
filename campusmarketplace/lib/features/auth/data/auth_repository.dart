import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../models/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  // Sign up
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('User registration failed');
    }

    await user.updateDisplayName(name.trim());

    final profile = UserProfile(
      id: user.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(profile.toFirestore());
    return profile;
  }

  // Sign in
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      return null;
    }

    return getUserProfile(user.uid);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      return null;
    }
  }

  // Watch user profile
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update profile
  Future<UserProfile> updateProfile({
    required String userId,
    required String name,
    String phone = '',
    XFile? newPhotoFile,
  }) async {
    String photoUrl = '';

    if (newPhotoFile != null) {
      final compressed = await ImageCompressor.compressImage(newPhotoFile);
      final ref = _storage.ref().child('profile_photos/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(compressed.path), SettableMetadata(contentType: 'image/jpeg'));
      photoUrl = await ref.getDownloadURL();
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
    };
    if (photoUrl.isNotEmpty) {
      updateData['photoUrl'] = photoUrl;
    }

    await _firestore.collection('users').doc(userId).set(updateData, SetOptions(merge: true));

    await _auth.currentUser?.updateDisplayName(name.trim());
    if (photoUrl.isNotEmpty) {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }

    final updated = await getUserProfile(userId);
    if (updated != null) {
      return updated;
    }

    return UserProfile(
      id: userId,
      name: name,
      email: _auth.currentUser?.email ?? '',
      phone: phone.trim(),
      photoUrl: photoUrl,
    );
  }
}
