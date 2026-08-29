import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ConditionBadge extends StatelessWidget {
  final String condition;
  final bool isSmall;

  const ConditionBadge({
    super.key,
    required this.condition,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.badgeSecondaryBg;
    Color text = AppColors.badgeSecondaryText;

    final normalizedCondition = condition.toLowerCase();

    if (normalizedCondition == 'new') {
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF2E7D32);
    } else if (normalizedCondition == 'like new') {
      bg = AppColors.primaryContainer;
      text = AppColors.primary;
    } else if (normalizedCondition == 'good') {
      bg = const Color(0xFFFFF3E0);
      text = const Color(0xFFE65100);
    }

    double horizontalPadding = 10;
    double verticalPadding = 4;
    double fontSize = 11;

    if (isSmall) {
      horizontalPadding = 6;
      verticalPadding = 2;
      fontSize = 10;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withAlpha(50), width: 0.8),
      ),
      child: Text(
        condition.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
