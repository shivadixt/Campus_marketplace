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
    Map<String, dynamic> data = {};
    if (doc.data() != null) {
      data = doc.data()!;
    }

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

    String itemSellerId = '';
    if (data['sellerId'] != null) {
      itemSellerId = data['sellerId'].toString();
    }

    String itemSellerName = 'Campus Seller';
    if (data['sellerName'] != null) {
      itemSellerName = data['sellerName'].toString();
    }

    String itemSellerPhone = '';
    if (data['sellerPhone'] != null) {
      itemSellerPhone = data['sellerPhone'].toString();
    }

    String itemSellerPhoto = '';
    if (data['sellerPhotoUrl'] != null) {
      itemSellerPhoto = data['sellerPhotoUrl'].toString();
    }

    String itemTitle = '';
    if (data['title'] != null) {
      itemTitle = data['title'].toString();
    }

    String itemDescription = '';
    if (data['description'] != null) {
      itemDescription = data['description'].toString();
    }

    String itemCategory = 'Others';
    if (data['category'] != null) {
      itemCategory = data['category'].toString();
    }

    String itemCondition = 'Good';
    if (data['condition'] != null) {
      itemCondition = data['condition'].toString();
    }

    String itemLocation = '';
    if (data['location'] != null) {
      itemLocation = data['location'].toString();
    }

    return Listing(
      id: doc.id,
      sellerId: itemSellerId,
      sellerName: itemSellerName,
      sellerPhone: itemSellerPhone,
      sellerPhotoUrl: itemSellerPhoto,
      title: itemTitle,
      description: itemDescription,
      price: itemPrice,
      category: itemCategory,
      condition: itemCondition,
      imageUrls: images,
      location: itemLocation,
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
    String newId = this.id;
    if (id != null) {
      newId = id;
    }

    String newSellerId = this.sellerId;
    if (sellerId != null) {
      newSellerId = sellerId;
    }

    String newSellerName = this.sellerName;
    if (sellerName != null) {
      newSellerName = sellerName;
    }

    String newSellerPhone = this.sellerPhone;
    if (sellerPhone != null) {
      newSellerPhone = sellerPhone;
    }

    String newSellerPhoto = this.sellerPhotoUrl;
    if (sellerPhotoUrl != null) {
      newSellerPhoto = sellerPhotoUrl;
    }

    String newTitle = this.title;
    if (title != null) {
      newTitle = title;
    }

    String newDescription = this.description;
    if (description != null) {
      newDescription = description;
    }

    double newPrice = this.price;
    if (price != null) {
      newPrice = price;
    }

    String newCategory = this.category;
    if (category != null) {
      newCategory = category;
    }

    String newCondition = this.condition;
    if (condition != null) {
      newCondition = condition;
    }

    List<String> newImages = this.imageUrls;
    if (imageUrls != null) {
      newImages = imageUrls;
    }

    String newLocation = this.location;
    if (location != null) {
      newLocation = location;
    }

    ListingStatus newStatus = this.status;
    if (status != null) {
      newStatus = status;
    }

    DateTime? newCreatedAt = this.createdAt;
    if (createdAt != null) {
      newCreatedAt = createdAt;
    }

    DateTime? newUpdatedAt = this.updatedAt;
    if (updatedAt != null) {
      newUpdatedAt = updatedAt;
    }

    return Listing(
      id: newId,
      sellerId: newSellerId,
      sellerName: newSellerName,
      sellerPhone: newSellerPhone,
      sellerPhotoUrl: newSellerPhoto,
      title: newTitle,
      description: newDescription,
      price: newPrice,
      category: newCategory,
      condition: newCondition,
      imageUrls: newImages,
      location: newLocation,
      status: newStatus,
      createdAt: newCreatedAt,
      updatedAt: newUpdatedAt,
    );
  }
}
