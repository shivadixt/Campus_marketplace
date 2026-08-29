import 'package:cloud_firestore/cloud_firestore.dart';
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
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

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

    final imageUrls = await _storageService.uploadListingImages(
      listingId: listingId,
      images: images,
      onProgress: onProgress,
    );

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
      final newlyUploadedUrls = await _storageService.uploadListingImages(
        listingId: existingListing.id,
        images: newImages,
        onProgress: onProgress,
      );
      updatedImageUrls.addAll(newlyUploadedUrls);
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

  // Watch active feed
  Stream<List<Listing>> watchActiveListings({String category = 'All'}) {
    Query<Map<String, dynamic>> query = _listingsRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    });
  }

  // Watch user listings
  Stream<List<Listing>> watchUserListings(String userId) {
    return _listingsRef
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    });
  }

  // Watch seller active listings
  Stream<List<Listing>> watchSellerActiveListings(String sellerId) {
    return _listingsRef
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    });
  }

  // Watch single listing
  Stream<Listing?> watchListing(String listingId) {
    return _listingsRef.doc(listingId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return Listing.fromFirestore(doc);
      }
      return null;
    });
  }
}
