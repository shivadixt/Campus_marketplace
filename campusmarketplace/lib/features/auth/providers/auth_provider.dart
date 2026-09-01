import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Stream provider for Firebase Auth user state
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Stream provider for active student profile
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authStateAsync = ref.watch(authStateProvider);

  final authUser = authStateAsync.asData?.value;
  if (authUser != null) {
    return repo.watchUserProfile(authUser.uid);
  }

  return Stream.value(null);
});

// Provider for fetching any seller profile by ID
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserProfile(userId);
});
