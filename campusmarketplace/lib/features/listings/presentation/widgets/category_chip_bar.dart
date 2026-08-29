import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/search_filter_provider.dart';

class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final allCategories = ['All', ...AppConstants.categories];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final bool isSelected = selectedCategory == cat;

          Color chipColor = AppColors.surface;
          Color borderColor = AppColors.border;
          Color textColor = AppColors.textPrimary;
          FontWeight textWeight = FontWeight.w500;
          Color iconColor = AppColors.textSecondary;

          if (isSelected) {
            chipColor = AppColors.primary;
            borderColor = AppColors.primary;
            textColor = Colors.white;
            textWeight = FontWeight.w600;
            iconColor = Colors.white;
          }

          return Material(
            color: chipColor,
            borderRadius: BorderRadius.circular(22),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = cat;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat != 'All') ...[
                      Icon(
                        AppConstants.getCategoryIcon(cat),
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: textWeight,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
