import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/presentation/my_profile_screen.dart';
import '../providers/listings_provider.dart';
import '../providers/search_filter_provider.dart';
import 'category_browse_screen.dart';
import 'create_edit_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'my_listings_screen.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/listing_card.dart';
import 'widgets/search_bar_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(filteredListingsProvider);
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    String greetingSubtitle = 'Campus Trading • Student';
    if (userProfile != null && userProfile.name.isNotEmpty) {
      greetingSubtitle = 'Campus Trading • ${userProfile.name}';
    }

    ImageProvider? userAvatarImage;
    if (userProfile != null && userProfile.photoUrl.isNotEmpty) {
      userAvatarImage = NetworkImage(userProfile.photoUrl);
    }

    Widget? avatarFallbackText;
    if (userAvatarImage == null) {
      String initial = 'U';
      if (userProfile != null && userProfile.name.isNotEmpty) {
        initial = userProfile.name[0].toUpperCase();
      }
      avatarFallbackText = Text(
        initial,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              greetingSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Browse Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryBrowseScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'My Listings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyListingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: userAvatarImage,
                child: avatarFallbackText,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      SearchBarWidget(),
                      SizedBox(height: 12),
                      CategoryChipBar(),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                final bool isSearching = searchQuery.isNotEmpty || selectedCategory != 'All';

                IconData emptyIcon = Icons.storefront_outlined;
                String emptyTitle = 'No items listed yet';
                String emptyMessage = 'Be the first student to list a textbook, calculator, or gear on campus!';
                String emptyButtonText = '+ List an Item';

                if (isSearching) {
                  emptyIcon = Icons.search_off_rounded;
                  emptyTitle = 'No matching items found';
                  emptyMessage = 'Try adjusting your search terms or clearing the category filter.';
                  emptyButtonText = 'Reset Filters';
                }

                return EmptyStateView(
                  icon: emptyIcon,
                  title: emptyTitle,
                  message: emptyMessage,
                  buttonText: emptyButtonText,
                  onButtonPressed: () {
                    if (isSearching) {
                      ref.read(selectedCategoryProvider.notifier).state = 'All';
                      ref.read(searchQueryProvider.notifier).state = '';
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
                      );
                    }
                  },
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(activeListingsStreamProvider);
                },
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListingDetailScreen(listing: listing),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            },
            error: (error, stack) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading listings: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Sell Item',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
          );
        },
      ),
    );
  }
}
