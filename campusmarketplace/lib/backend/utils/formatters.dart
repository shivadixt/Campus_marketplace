import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // Price formatter
  static String formatPrice(double price) {
    int decimalDigits = 0;
    if (price % 1 != 0) {
      decimalDigits = 2;
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: decimalDigits,
    );
    return formatter.format(price);
  }

  // Relative time formatter
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat('d MMM yyyy').format(dateTime);
  }

  // Date formatter
  static String formatMemberSince(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Recently';
    }
    return DateFormat('MMM yyyy').format(dateTime);
  }
}
