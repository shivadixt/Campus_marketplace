import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { active, sold }

class Listing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String sellerPhotoUrl;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final String location;
  final ListingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone = '',
    this.sellerPhotoUrl = '',
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.location,
    this.status = ListingStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSold {
    return status == ListingStatus.sold;
  }

  bool get isActive {
    return status == ListingStatus.active;
  }

  // From Firestore
  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? createdTime;
    if (data['createdAt'] is Timestamp) {
      createdTime = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedTime;
    if (data['updatedAt'] is Timestamp) {
      updatedTime = (data['updatedAt'] as Timestamp).toDate();
    }

    ListingStatus itemStatus = ListingStatus.active;
    if (data['status'] == 'sold') {
      itemStatus = ListingStatus.sold;
    }

    double itemPrice = 0.0;
    if (data['price'] is num) {
      itemPrice = (data['price'] as num).toDouble();
    }

    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls']);
    }

    return Listing(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Campus Seller',
      sellerPhone: data['sellerPhone'] ?? '',
      sellerPhotoUrl: data['sellerPhotoUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: itemPrice,
      category: data['category'] ?? 'Others',
      condition: data['condition'] ?? 'Good',
      imageUrls: images,
      location: data['location'] ?? '',
      status: itemStatus,
      createdAt: createdTime,
      updatedAt: updatedTime,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    String statusString = 'active';
    if (status == ListingStatus.sold) {
      statusString = 'sold';
    }

    dynamic createdValue = FieldValue.serverTimestamp();
    if (createdAt != null) {
      createdValue = Timestamp.fromDate(createdAt!);
    }

    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerPhotoUrl': sellerPhotoUrl,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'location': location,
      'status': statusString,
      'createdAt': createdValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with
  Listing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerPhotoUrl,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? location,
    ListingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
