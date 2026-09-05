import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _auth = _resolveAuth(auth),
        _firestore = _resolveFirestore(firestore),
        _storageService = _resolveStorageService(storageService);

  static FirebaseAuth _resolveAuth(FirebaseAuth? auth) {
    if (auth != null) {
      return auth;
    }
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore _resolveFirestore(FirebaseFirestore? firestore) {
    if (firestore != null) {
      return firestore;
    }
    return FirebaseFirestore.instance;
  }

  static StorageService _resolveStorageService(StorageService? storageService) {
    if (storageService != null) {
      return storageService;
    }
    return StorageService();
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  // Sign up with email and password
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

  // Google Sign In
  Future<UserProfile?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      return null;
    }

    // Check if profile already exists in Firestore
    final existingProfile = await getUserProfile(user.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    // First time Google login, create new profile
    String studentName = 'Campus Student';
    if (user.displayName != null) {
      if (user.displayName!.isNotEmpty) {
        studentName = user.displayName!;
      }
    }

    String studentEmail = '';
    if (user.email != null) {
      studentEmail = user.email!;
    }

    String studentPhoto = '';
    if (user.photoURL != null) {
      studentPhoto = user.photoURL!;
    }

    final newProfile = UserProfile(
      id: user.uid,
      name: studentName,
      email: studentEmail,
      photoUrl: studentPhoto,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(newProfile.toFirestore());
    return newProfile;
  }

  // Sign in with email and password
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
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Google sign out note: $e');
    }
    await _auth.signOut();
  }

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        if (doc.data() != null) {
          return UserProfile.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      return null;
    }
  }

  // Watch user profile in real-time
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        if (doc.data() != null) {
          return UserProfile.fromFirestore(doc);
        }
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
      try {
        photoUrl = await _storageService.uploadImageToCloudinary(
          imageFile: newPhotoFile,
          folder: 'campus_marketplace/profiles/$userId',
        );
      } catch (e) {
        debugPrint('Avatar Cloudinary upload error: $e');
        photoUrl = newPhotoFile.path;
      }
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
    };
    if (photoUrl.isNotEmpty) {
      updateData['photoUrl'] = photoUrl;
    }

    await _firestore.collection('users').doc(userId).set(updateData, SetOptions(merge: true));

    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name.trim());
      if (photoUrl.isNotEmpty) {
        await _auth.currentUser!.updatePhotoURL(photoUrl);
      }
    }

    final updated = await getUserProfile(userId);
    if (updated != null) {
      return updated;
    }

    String fallbackEmail = '';
    if (_auth.currentUser != null) {
      if (_auth.currentUser!.email != null) {
        fallbackEmail = _auth.currentUser!.email!;
      }
    }

    return UserProfile(
      id: userId,
      name: name,
      email: fallbackEmail,
      phone: phone.trim(),
      photoUrl: photoUrl,
    );
  }
}
