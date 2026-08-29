import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/listing_model.dart';
import 'listings_provider.dart';

// --- Filter State Providers ---
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedConditionProvider = StateProvider<String?>((ref) => null);

// --- Filtered Listings Provider ---
final filteredListingsProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final listingsAsync = ref.watch(activeListingsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final selectedCondition = ref.watch(selectedConditionProvider);

  return listingsAsync.whenData((listings) {
    final List<Listing> result = [];

    for (final listing in listings) {
      if (selectedCategory != 'All' && listing.category != selectedCategory) {
        continue;
      }

      if (selectedCondition != null && listing.condition != selectedCondition) {
        continue;
      }

      if (query.isNotEmpty) {
        final bool titleMatch = listing.title.toLowerCase().contains(query);
        final bool descMatch = listing.description.toLowerCase().contains(query);
        final bool locMatch = listing.location.toLowerCase().contains(query);
        final bool catMatch = listing.category.toLowerCase().contains(query);

        if (!titleMatch && !descMatch && !locMatch && !catMatch) {
          continue;
        }
      }

      result.add(listing);
    }

    return result;
  });
});
