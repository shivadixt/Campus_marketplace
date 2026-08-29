import 'package:flutter_test/flutter_test.dart';
import 'package:campus_marketplace/core/utils/formatters.dart';
import 'package:campus_marketplace/core/utils/validators.dart';
import 'package:campus_marketplace/models/listing_model.dart';
import 'package:campus_marketplace/models/user_profile.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail validates correctly', () {
      expect(Validators.validateEmail(''), 'Email is required');
      expect(Validators.validateEmail('invalid'), 'Please enter a valid email address');
      expect(Validators.validateEmail('student@campus.edu'), isNull);
    });

    test('validatePassword validates length', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword('123'), 'Password must be at least 6 characters');
      expect(Validators.validatePassword('secret123'), isNull);
    });

    test('validatePrice validates numeric prices', () {
      expect(Validators.validatePrice(''), 'Price is required');
      expect(Validators.validatePrice('abc'), 'Please enter a valid numeric price');
      expect(Validators.validatePrice('-10'), 'Price cannot be negative');
      expect(Validators.validatePrice('450'), isNull);
      expect(Validators.validatePrice('99.50'), isNull);
    });
  });

  group('Formatters Unit Tests', () {
    test('formatPrice formats correctly', () {
      expect(Formatters.formatPrice(500), '₹500');
      expect(Formatters.formatPrice(45.50), '₹45.50');
    });

    test('formatRelativeTime formats correctly', () {
      final now = DateTime.now();
      expect(Formatters.formatRelativeTime(now), 'Just now');
      expect(
        Formatters.formatRelativeTime(now.subtract(const Duration(minutes: 5))),
        '5m ago',
      );
      expect(
        Formatters.formatRelativeTime(now.subtract(const Duration(hours: 2))),
        '2h ago',
      );
      expect(
        Formatters.formatRelativeTime(now.subtract(const Duration(days: 3))),
        '3d ago',
      );
    });
  });

  group('Data Models Unit Tests', () {
    test('UserProfile toFirestore and copyWith', () {
      final profile = UserProfile(
        id: 'u123',
        name: 'Jane Doe',
        email: 'jane@campus.edu',
        phone: '+919876543210',
      );

      final map = profile.toFirestore();
      expect(map['name'], 'Jane Doe');
      expect(map['email'], 'jane@campus.edu');
      expect(map['phone'], '+919876543210');

      final updated = profile.copyWith(name: 'Jane Smith');
      expect(updated.name, 'Jane Smith');
      expect(updated.id, 'u123');
    });

    test('Listing toFirestore and status properties', () {
      final listing = Listing(
        id: 'l1',
        sellerId: 'u123',
        sellerName: 'Jane Doe',
        title: 'Casio Calculator',
        description: 'Hardly used',
        price: 500.0,
        category: 'Calculators',
        condition: 'Like New',
        imageUrls: ['https://example.com/img.jpg'],
        location: 'Hostel 4',
        status: ListingStatus.active,
      );

      expect(listing.isActive, isTrue);
      expect(listing.isSold, isFalse);

      final map = listing.toFirestore();
      expect(map['title'], 'Casio Calculator');
      expect(map['status'], 'active');
      expect(map['category'], 'Calculators');

      final soldListing = listing.copyWith(status: ListingStatus.sold);
      expect(soldListing.isSold, isTrue);
      expect(soldListing.isActive, isFalse);
    });
  });
}
