import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../listings/presentation/listing_detail_screen.dart';
import '../../listings/presentation/widgets/empty_state_view.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../listings/providers/listings_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  final String initialSellerName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.initialSellerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerProfileAsync = ref.watch(userProfileProvider(sellerId));
    final activeListingsAsync = ref.watch(sellerActiveListingsProvider(sellerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seller header card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: sellerProfileAsync.when(
                  data: (profile) {
                    String name = initialSellerName;
                    if (profile != null && profile.name.isNotEmpty) {
                      name = profile.name;
                    }

                    String photoUrl = '';
                    if (profile != null && profile.photoUrl.isNotEmpty) {
                      photoUrl = profile.photoUrl;
                    }

                    final memberSince = Formatters.formatMemberSince(profile?.createdAt);

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryContainer,
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Campus Student',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Member since $memberSince',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  },
                  error: (_, _) {
                    return Text(initialSellerName);
                  },
                ),
              ),

              // Section title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Active Listings by Seller',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // Active listings grid
              activeListingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No active items',
                      message: 'This seller currently does not have any active listings.',
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final item = listings[index];
                      return ListingCard(
                        listing: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listing: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                },
                error: (err, _) {
                  return Center(child: Text('Error: $err'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
