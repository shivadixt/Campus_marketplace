import 'dart:async';
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

  // Demo state
  static UserProfile? _demoProfile;
  final StreamController<UserProfile?> _demoProfileController = StreamController<UserProfile?>.broadcast();

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = _resolveAuth(auth),
        _firestore = _resolveFirestore(firestore),
        _storage = _resolveStorage(storage);

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

  static FirebaseStorage _resolveStorage(FirebaseStorage? storage) {
    if (storage != null) {
      return storage;
    }
    return FirebaseStorage.instance;
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  UserProfile? get currentDemoProfile {
    return _demoProfile;
  }

  // Demo student login
  Future<UserProfile> signInWithDemoStudent({
    String email = 'shiva.dixit_cs24@gla.ac.in',
    String name = 'Shiva Dixit',
    String phone = '8218071428',
  }) async {
    _demoProfile = UserProfile(
      id: 'demo_student_101',
      name: name,
      email: email,
      phone: phone,
      createdAt: DateTime(2024, 8, 1),
    );
    _demoProfileController.add(_demoProfile);
    return _demoProfile!;
  }

  // Sign up
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    try {
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
    } catch (e) {
      debugPrint('Firebase signUp error: $e');
      return signInWithDemoStudent(email: email, name: name, phone: phone);
    }
  }

  // Sign in
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return null;
      }

      return getUserProfile(user.uid);
    } catch (e) {
      debugPrint('Firebase signIn error: $e');
      return signInWithDemoStudent(email: email, name: email.split('@').first);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _demoProfile = null;
    _demoProfileController.add(null);
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Signout note: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    if (_demoProfile != null) {
      if (_demoProfile!.id == userId) {
        return _demoProfile;
      }
    }

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
      return _demoProfile;
    }
  }

  // Watch user profile
  Stream<UserProfile?> watchUserProfile(String userId) {
    if (_demoProfile != null) {
      return _demoProfileController.stream;
    }

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        if (doc.data() != null) {
          return UserProfile.fromFirestore(doc);
        }
      }
      return _demoProfile;
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
        final compressed = await ImageCompressor.compressImage(newPhotoFile);
        final ref = _storage.ref().child('profile_photos/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(compressed.path), SettableMetadata(contentType: 'image/jpeg'));
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Avatar storage upload notice: $e');
        photoUrl = newPhotoFile.path;
      }
    }

    if (_demoProfile != null) {
      String currentPhoto = _demoProfile!.photoUrl;
      if (photoUrl.isNotEmpty) {
        currentPhoto = photoUrl;
      }

      _demoProfile = _demoProfile!.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        photoUrl: currentPhoto,
      );
      _demoProfileController.add(_demoProfile);
      return _demoProfile!;
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
    };
    if (photoUrl.isNotEmpty) {
      updateData['photoUrl'] = photoUrl;
    }

    try {
      await _firestore.collection('users').doc(userId).set(updateData, SetOptions(merge: true));
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name.trim());
        if (photoUrl.isNotEmpty) {
          await _auth.currentUser!.updatePhotoURL(photoUrl);
        }
      }
    } catch (e) {
      debugPrint('Firestore profile update notice: $e');
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
