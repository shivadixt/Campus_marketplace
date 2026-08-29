import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for Firebase Auth user state
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Stream provider for current logged-in user profile from Firestore
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchUserProfile(authUser.uid);
});

/// Provider for fetching any seller's profile by ID
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserProfile(userId);
});
