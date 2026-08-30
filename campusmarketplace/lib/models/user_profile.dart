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

    String userName = 'Student';
    if (data['name'] != null) {
      userName = data['name'].toString();
    }

    String userEmail = '';
    if (data['email'] != null) {
      userEmail = data['email'].toString();
    }

    String userPhone = '';
    if (data['phone'] != null) {
      userPhone = data['phone'].toString();
    }

    String userPhoto = '';
    if (data['photoUrl'] != null) {
      userPhoto = data['photoUrl'].toString();
    }

    DateTime? createdTime;
    final timestamp = data['createdAt'];
    if (timestamp is Timestamp) {
      createdTime = timestamp.toDate();
    }

    return UserProfile(
      id: doc.id,
      name: userName,
      email: userEmail,
      phone: userPhone,
      photoUrl: userPhoto,
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
    String newId = this.id;
    if (id != null) {
      newId = id;
    }

    String newName = this.name;
    if (name != null) {
      newName = name;
    }

    String newEmail = this.email;
    if (email != null) {
      newEmail = email;
    }

    String newPhone = this.phone;
    if (phone != null) {
      newPhone = phone;
    }

    String newPhoto = this.photoUrl;
    if (photoUrl != null) {
      newPhoto = photoUrl;
    }

    DateTime? newCreatedAt = this.createdAt;
    if (createdAt != null) {
      newCreatedAt = createdAt;
    }

    return UserProfile(
      id: newId,
      name: newName,
      email: newEmail,
      phone: newPhone,
      photoUrl: newPhoto,
      createdAt: newCreatedAt,
    );
  }
}
