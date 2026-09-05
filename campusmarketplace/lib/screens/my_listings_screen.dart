import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart';
import '../providers/listings_provider.dart';
import 'create_edit_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'widgets/condition_badge.dart';
import 'widgets/empty_state_view.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final authUser = ref.watch(authStateProvider).value;

    String currentUserId = '';
    if (profile != null) {
      currentUserId = profile.id;
    } else if (authUser != null) {
      currentUserId = authUser.uid;
    }

    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please log in to manage your listings.')),
      );
    }

    final listingsAsync = ref.watch(userListingsProvider(currentUserId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Active Listings'),
              Tab(text: 'Sold History'),
            ],
          ),
        ),
        body: listingsAsync.when(
          data: (allListings) {
            final List<Listing> activeListings = [];
            final List<Listing> soldListings = [];

            for (final item in allListings) {
              if (item.isActive) {
                activeListings.add(item);
              } else if (item.isSold) {
                soldListings.add(item);
              }
            }

            return TabBarView(
              children: [
                _buildListingsTab(context, ref, activeListings, isSoldTab: false),
                _buildListingsTab(context, ref, soldListings, isSoldTab: true),
              ],
            );
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          },
          error: (error, stack) {
            return Center(
              child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Listing', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListingsTab(
    BuildContext context,
    WidgetRef ref,
    List<Listing> listings, {
    required bool isSoldTab,
  }) {
    if (listings.isEmpty) {
      IconData emptyIcon = Icons.inventory_2_outlined;
      String emptyTitle = 'No active listings';
      String emptyMessage = 'You haven\'t posted any active listings. Tap "+ New Listing" to start selling!';
      String? emptyButtonText = '+ Post Item';
      VoidCallback? onButtonTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
        );
      };

      if (isSoldTab) {
        emptyIcon = Icons.receipt_long_outlined;
        emptyTitle = 'No sold items yet';
        emptyMessage = 'Items you mark as sold will appear here for your selling history.';
        emptyButtonText = null;
        onButtonTap = null;
      }

      return EmptyStateView(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
        buttonText: emptyButtonText,
        onButtonPressed: onButtonTap,
      );
    }

    final repo = ref.read(listingsRepositoryProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = listings[index];

        String? firstImage;
        if (item.imageUrls.isNotEmpty) {
          firstImage = item.imageUrls.first;
        }

        Widget imageWidget;
        if (firstImage != null) {
          imageWidget = CachedNetworkImage(
            imageUrl: firstImage,
            fit: BoxFit.cover,
          );
        } else {
          imageWidget = Container(
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textTertiary),
          );
        }

        String toggleStatusText = 'Mark Sold';
        IconData toggleStatusIcon = Icons.check_circle_outline_rounded;
        Color toggleStatusColor = AppColors.success;

        if (item.isSold) {
          toggleStatusText = 'Reactivate';
          toggleStatusIcon = Icons.replay_rounded;
          toggleStatusColor = AppColors.textPrimary;
        }

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: imageWidget,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatPrice(item.price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            ConditionBadge(condition: item.condition, isSmall: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.category} • ${Formatters.formatRelativeTime(item.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(
                                toggleStatusIcon,
                                size: 16,
                                color: toggleStatusColor,
                              ),
                              label: Text(
                                toggleStatusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: toggleStatusColor,
                                ),
                              ),
                              onPressed: () async {
                                if (item.isSold) {
                                  await repo.markAsActive(item.id);
                                } else {
                                  await repo.markAsSold(item.id);
                                }
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateEditListingScreen(existingListing: item),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Listing?'),
                                    content: const Text('Are you sure you want to permanently delete this listing?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await repo.deleteListing(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
