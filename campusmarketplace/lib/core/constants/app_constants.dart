import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Campus Marketplace';

  // Cloudinary configuration
  static const String cloudinaryCloudName = 'x6rkroh7';
  static const String cloudinaryUploadPreset = 'campus_preset';

  // Categories
  static const List<String> categories = [
    'Books',
    'Electronics',
    'Furniture',
    'Calculators',
    'Stationery',
    'Others',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Books':
        return Icons.menu_book_rounded;
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Furniture':
        return Icons.chair_rounded;
      case 'Calculators':
        return Icons.calculate_rounded;
      case 'Stationery':
        return Icons.edit_note_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  // Item conditions
  static const List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Used',
  ];

  // Configuration
  static const int maxListingImages = 4;
  static const int minListingImages = 1;
  static const int maxImageDimension = 1080;
  static const int imageCompressionQuality = 70;
}
