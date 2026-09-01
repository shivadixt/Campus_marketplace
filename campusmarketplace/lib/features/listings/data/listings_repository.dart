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

    await _listingsRef.doc(listingId).set(listing.toFirestore());
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

    await _listingsRef.doc(existingListing.id).update(updated.toFirestore());
    return updated;
  }

  // Mark as sold
  Future<void> markAsSold(String listingId) async {
    await _listingsRef.doc(listingId).update({
      'status': 'sold',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark as active
  Future<void> markAsActive(String listingId) async {
    await _listingsRef.doc(listingId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    await _listingsRef.doc(listingId).delete();
    await _storageService.deleteListingFolder(listingId);
  }

  // Helper to compare dates cleanly
  static int _compareCreatedAt(Listing a, Listing b) {
    final dateA = a.createdAt;
    final dateB = b.createdAt;
    if (dateA == null && dateB == null) {
      return 0;
    }
    if (dateA == null) {
      return 1;
    }
    if (dateB == null) {
      return -1;
    }
    return dateB.compareTo(dateA);
  }

  // Watch active feed
  Stream<List<Listing>> watchActiveListings({String category = 'All'}) {
    return _listingsRef
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final List<Listing> list = [];
      for (final doc in snapshot.docs) {
        final item = Listing.fromFirestore(doc);
        if (category.isEmpty || category == 'All' || item.category == category) {
          list.add(item);
        }
      }
      list.sort(_compareCreatedAt);
      return list;
    });
  }

  // Watch user listings
  Stream<List<Listing>> watchUserListings(String userId) {
    return _listingsRef
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<Listing> list = [];
      for (final doc in snapshot.docs) {
        list.add(Listing.fromFirestore(doc));
      }
      list.sort(_compareCreatedAt);
      return list;
    });
  }

  // Watch seller active listings
  Stream<List<Listing>> watchSellerActiveListings(String sellerId) {
    return _listingsRef
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final List<Listing> list = [];
      for (final doc in snapshot.docs) {
        final item = Listing.fromFirestore(doc);
        if (item.isActive) {
          list.add(item);
        }
      }
      list.sort(_compareCreatedAt);
      return list;
    });
  }

  // Watch single listing
  Stream<Listing?> watchListing(String listingId) {
    return _listingsRef.doc(listingId).snapshots().map((doc) {
      if (doc.exists) {
        if (doc.data() != null) {
          return Listing.fromFirestore(doc);
        }
      }
      return null;
    });
  }
}
