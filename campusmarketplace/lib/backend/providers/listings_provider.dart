import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../services/listings_repository.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ListingsRepository(storageService: storageService);
});

/// Stream of all active listings
final activeListingsStreamProvider = StreamProvider<List<Listing>>((ref) {
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.watchActiveListings();
});

/// Stream of active listings filtered by category
final activeListingsByCategoryProvider = StreamProvider.family<List<Listing>, String>((ref, category) {
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.watchActiveListings(category: category);
});

/// Stream of current user's listings (all active & sold)
final userListingsProvider = StreamProvider.family<List<Listing>, String>((ref, userId) {
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.watchUserListings(userId);
});

/// Stream of a specific seller's active listings
final sellerActiveListingsProvider = StreamProvider.family<List<Listing>, String>((ref, sellerId) {
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.watchSellerActiveListings(sellerId);
});

/// Stream of a single listing by ID
final singleListingProvider = StreamProvider.family<Listing?, String>((ref, listingId) {
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.watchListing(listingId);
});
