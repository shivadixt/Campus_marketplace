import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.createdAt,
  });

  // From Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return UserProfile(id: doc.id, name: 'Student', email: '');
    }

    DateTime? createdTime;
    final timestamp = data['createdAt'];
    if (timestamp is Timestamp) {
      createdTime = timestamp.toDate();
    }

    return UserProfile(
      id: doc.id,
      name: data['name'] ?? 'Student',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      createdAt: createdTime,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    dynamic timeValue = FieldValue.serverTimestamp();
    if (createdAt != null) {
      timeValue = Timestamp.fromDate(createdAt!);
    }

    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': timeValue,
    };
  }

  // Copy with
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
