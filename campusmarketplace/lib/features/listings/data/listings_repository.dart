import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../models/listing_model.dart';
import 'storage_service.dart';

class ListingsRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  // In-Memory Sample Listings for instant test/demo
  static final List<Listing> _localListings = [
    Listing(
      id: 'demo_item_1',
      sellerId: 'demo_seller_1',
      sellerName: 'Rahul Sharma',
      sellerPhone: '+91 98765 43211',
      sellerPhotoUrl: '',
      title: 'Casio FX-991EX Scientific Calculator',
      description: 'Barely used for 1 semester in Engineering Math. Mint condition with original hard cover and manual.',
      price: 650.0,
      category: 'Calculators',
      condition: 'Like New',
      imageUrls: [
        'https://images.unsplash.com/photo-1594980596870-8aa52a78d8cd?w=600&auto=format&fit=crop&q=80',
      ],
      location: 'Hostel Block A, Room 204',
      status: ListingStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Listing(
      id: 'demo_item_2',
      sellerId: 'demo_seller_2',
      sellerName: 'Priya Singh',
      sellerPhone: '+91 98765 43212',
      sellerPhotoUrl: '',
      title: 'Concepts of Physics (HC Verma Vol 1 & 2)',
      description: 'Complete set with handwritten solved formula notes. Essential for 1st year engineering physics.',
      price: 450.0,
      category: 'Books',
      condition: 'Good',
      imageUrls: [
        'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
      ],
      location: 'Central Library Lawn',
      status: ListingStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Listing(
      id: 'demo_item_3',
      sellerId: 'demo_student_101',
      sellerName: 'Shiva Dixit',
      sellerPhone: '8218071428',
      sellerPhotoUrl: '',
      title: 'Sony Wireless Noise Cancelling Headphones',
      description: 'Super comfortable for studying in noisy hostels. Great battery backup (30+ hours) with aux cable.',
      price: 1200.0,
      category: 'Electronics',
      condition: 'Like New',
      imageUrls: [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&auto=format&fit=crop&q=80',
      ],
      location: 'Computer Science Dept Lab 3',
      status: ListingStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Listing(
      id: 'demo_item_4',
      sellerId: 'demo_seller_3',
      sellerName: 'Amit Kumar',
      sellerPhone: '+91 98765 43213',
      sellerPhotoUrl: '',
      title: 'Wooden Study Desk & Ergonomic Chair',
      description: 'Solid wooden desk suitable for laptop and book reading. Easy to assemble, moving out of hostel.',
      price: 1400.0,
      category: 'Furniture',
      condition: 'Used',
      imageUrls: [
        'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=600&auto=format&fit=crop&q=80',
      ],
      location: 'Hostel Block C Ground Floor',
      status: ListingStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final StreamController<List<Listing>> _localStreamController =
      StreamController<List<Listing>>.broadcast();

  ListingsRepository({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = _resolveFirestore(firestore),
        _storageService = _resolveStorageService(storageService);

  static FirebaseFirestore _resolveFirestore(FirebaseFirestore? firestore) {
    if (firestore != null) {
      return firestore;
    }
    return FirebaseFirestore.instance;
  }

  static StorageService _resolveStorageService(StorageService? storageService) {
    if (storageService != null) {
      return storageService;
    }
    return StorageService();
  }

  CollectionReference<Map<String, dynamic>> get _listingsRef {
    return _firestore.collection('listings');
  }

  // Create listing
  Future<Listing> createListing({
    required String sellerId,
    required String sellerName,
    String sellerPhone = '',
    String sellerPhotoUrl = '',
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
    required List<XFile> images,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    final listingId = const Uuid().v4();

    List<String> imageUrls = [];
    try {
      imageUrls = await _storageService.uploadListingImages(
        listingId: listingId,
        images: images,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Storage upload note: $e');
      imageUrls = images.map((f) => f.path).toList();
    }

    final listing = Listing(
      id: listingId,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerPhotoUrl: sellerPhotoUrl,
      title: title.trim(),
      description: description.trim(),
      price: price,
      category: category,
      condition: condition,
      imageUrls: imageUrls,
      location: location.trim(),
      status: ListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to local list for instant reactivity
    _localListings.insert(0, listing);
    _localStreamController.add(List.from(_localListings));

    try {
      await _listingsRef.doc(listingId).set(listing.toFirestore());
    } catch (e) {
      debugPrint('Firestore write note: $e');
    }

    return listing;
  }

  // Update listing
  Future<Listing> updateListing({
    required Listing existingListing,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
    List<String> retainedImageUrls = const [],
    List<XFile> newImages = const [],
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    final List<String> updatedImageUrls = List<String>.from(retainedImageUrls);

    if (newImages.isNotEmpty) {
      try {
        final newlyUploadedUrls = await _storageService.uploadListingImages(
          listingId: existingListing.id,
          images: newImages,
          onProgress: onProgress,
        );
        updatedImageUrls.addAll(newlyUploadedUrls);
      } catch (e) {
        debugPrint('Storage upload update note: $e');
        updatedImageUrls.addAll(newImages.map((f) => f.path));
      }
    }

    final updated = existingListing.copyWith(
      title: title.trim(),
      description: description.trim(),
      price: price,
      category: category,
      condition: condition,
      location: location.trim(),
      imageUrls: updatedImageUrls,
      updatedAt: DateTime.now(),
    );

    // Update in local list
    final index = _localListings.indexWhere((l) => l.id == existingListing.id);
    if (index != -1) {
      _localListings[index] = updated;
      _localStreamController.add(List.from(_localListings));
    }

    try {
      await _listingsRef.doc(existingListing.id).update(updated.toFirestore());
    } catch (e) {
      debugPrint('Firestore update note: $e');
    }

    return updated;
  }

  // Mark as sold
  Future<void> markAsSold(String listingId) async {
    final index = _localListings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _localListings[index] = _localListings[index].copyWith(status: ListingStatus.sold);
      _localStreamController.add(List.from(_localListings));
    }

    try {
      await _listingsRef.doc(listingId).update({
        'status': 'sold',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore mark sold note: $e');
    }
  }

  // Mark as active
  Future<void> markAsActive(String listingId) async {
    final index = _localListings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _localListings[index] = _localListings[index].copyWith(status: ListingStatus.active);
      _localStreamController.add(List.from(_localListings));
    }

    try {
      await _listingsRef.doc(listingId).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore mark active note: $e');
    }
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    _localListings.removeWhere((l) => l.id == listingId);
    _localStreamController.add(List.from(_localListings));

    try {
      await _listingsRef.doc(listingId).delete();
      await _storageService.deleteListingFolder(listingId);
    } catch (e) {
      debugPrint('Firestore delete note: $e');
    }
  }

  // Watch active feed
  Stream<List<Listing>> watchActiveListings({String category = 'All'}) {
    try {
      Query<Map<String, dynamic>> query = _listingsRef
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (category.isNotEmpty && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      return query.snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
        }
        return _filterLocalActive(category);
      });
    } catch (e) {
      return Stream.value(_filterLocalActive(category));
    }
  }

  List<Listing> _filterLocalActive(String category) {
    final active = _localListings.where((l) => l.isActive).toList();
    if (category.isNotEmpty && category != 'All') {
      return active.where((l) => l.category == category).toList();
    }
    return active;
  }

  // Watch user listings
  Stream<List<Listing>> watchUserListings(String userId) {
    try {
      return _listingsRef
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
        }
        return _localListings.where((l) => l.sellerId == userId).toList();
      });
    } catch (e) {
      return Stream.value(_localListings.where((l) => l.sellerId == userId).toList());
    }
  }

  // Watch seller active listings
  Stream<List<Listing>> watchSellerActiveListings(String sellerId) {
    try {
      return _listingsRef
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
        }
        return _localListings.where((l) => l.sellerId == sellerId && l.isActive).toList();
      });
    } catch (e) {
      return Stream.value(_localListings.where((l) => l.sellerId == sellerId && l.isActive).toList());
    }
  }

  // Watch single listing
  Stream<Listing?> watchListing(String listingId) {
    try {
      return _listingsRef.doc(listingId).snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return Listing.fromFirestore(doc);
        }
        final match = _localListings.where((l) => l.id == listingId).toList();
        if (match.isNotEmpty) {
          return match.first;
        }
        return null;
      });
    } catch (e) {
      final match = _localListings.where((l) => l.id == listingId).toList();
      if (match.isNotEmpty) {
        return Stream.value(match.first);
      }
      return Stream.value(null);
    }
  }
}
