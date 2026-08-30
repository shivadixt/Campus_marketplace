import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/contact_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/listing_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/presentation/seller_profile_screen.dart';
import '../providers/listings_provider.dart';
import 'create_edit_listing_screen.dart';
import 'widgets/condition_badge.dart';
import 'widgets/image_carousel.dart';

class ListingDetailScreen extends ConsumerWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(singleListingProvider(listing.id));

    Listing currentListing = listing;
    if (listingAsync.value != null) {
      currentListing = listingAsync.value!;
    }

    String currentUserId = '';
    final profile = ref.watch(currentUserProfileProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    if (profile != null) {
      currentUserId = profile.id;
    } else if (authUser != null) {
      currentUserId = authUser.uid;
    }

    final bool isOwner = currentUserId == currentListing.sellerId;

    String toggleSoldText = 'Mark as Sold';
    IconData toggleSoldIcon = Icons.check_circle_outline_rounded;
    if (currentListing.isSold) {
      toggleSoldText = 'Mark as Active';
      toggleSoldIcon = Icons.replay_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentListing.title),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                final repo = ref.read(listingsRepositoryProvider);
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEditListingScreen(existingListing: currentListing),
                    ),
                  );
                } else if (value == 'toggle_sold') {
                  if (currentListing.isSold) {
                    await repo.markAsActive(currentListing.id);
                  } else {
                    await repo.markAsSold(currentListing.id);
                  }
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Listing?'),
                      content: const Text('This will permanently delete this listing and its photos.'),
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
                    await repo.deleteListing(currentListing.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text('Edit Listing'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_sold',
                  child: Row(
                    children: [
                      Icon(toggleSoldIcon, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text(toggleSoldText),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photos
              ImageCarousel(imageUrls: currentListing.imageUrls),

              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentListing.isSold) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.badgeSecondaryBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'This item has been marked as SOLD',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Price and condition
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatPrice(currentListing.price),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        ConditionBadge(condition: currentListing.condition),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      currentListing.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category and location
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppConstants.getCategoryIcon(currentListing.category),
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentListing.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                currentListing.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Posted ${Formatters.formatRelativeTime(currentListing.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentListing.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Seller card
                    const Text(
                      'Seller Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(
                                sellerId: currentListing.sellerId,
                                initialSellerName: currentListing.sellerName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryContainer,
                                backgroundImage: currentListing.sellerPhotoUrl.isNotEmpty
                                    ? NetworkImage(currentListing.sellerPhotoUrl)
                                    : null,
                                child: currentListing.sellerPhotoUrl.isEmpty
                                    ? Text(
                                        currentListing.sellerName.isNotEmpty
                                            ? currentListing.sellerName[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentListing.sellerName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Campus Student • Tap to view profile & listings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildBottomAction(context, ref, currentListing, isOwner),
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    Listing currentListing,
    bool isOwner,
  ) {
    if (isOwner) {
      String toggleButtonText = 'Mark as Sold';
      IconData toggleIcon = Icons.check_circle_outline_rounded;
      if (currentListing.isSold) {
        toggleButtonText = 'Reactivate';
        toggleIcon = Icons.replay_rounded;
      }

      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Listing'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEditListingScreen(existingListing: currentListing),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(toggleIcon, size: 18),
              label: Text(toggleButtonText),
              onPressed: () async {
                final repo = ref.read(listingsRepositoryProvider);
                if (currentListing.isSold) {
                  await repo.markAsActive(currentListing.id);
                } else {
                  await repo.markAsSold(currentListing.id);
                }
              },
            ),
          ),
        ],
      );
    }

    VoidCallback? contactAction;
    if (!currentListing.isSold) {
      contactAction = () {
        _handleContactSeller(context, currentListing);
      };
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
      label: const Text('Contact Seller'),
      onPressed: contactAction,
    );
  }

  void _handleContactSeller(BuildContext context, Listing listing) {
    if (listing.sellerPhone.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seller Contact'),
          content: Text(
            'Seller (${listing.sellerName}) has not linked a phone number.\nYou can meet them at their campus location:\n"${listing.location}"',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact ${listing.sellerName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF2E7D32)),
                ),
                title: const Text('WhatsApp Chat (Recommended)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send prefilled message about this item'),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactHelper.openWhatsApp(
                    phone: listing.sellerPhone,
                    sellerName: listing.sellerName,
                    listingTitle: listing.title,
                    context: context,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sms_outlined, color: AppColors.primary),
                ),
                title: const Text('SMS / Text Message', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send SMS inquiry to seller phone'),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactHelper.openSms(
                    phone: listing.sellerPhone,
                    sellerName: listing.sellerName,
                    listingTitle: listing.title,
                    context: context,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_outlined, color: AppColors.textPrimary),
                ),
                title: const Text('Phone Call', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(listing.sellerPhone),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactHelper.openPhoneDialer(phone: listing.sellerPhone, context: context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
