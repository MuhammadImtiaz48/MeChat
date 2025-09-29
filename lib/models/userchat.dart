import 'package:cloud_firestore/cloud_firestore.dart';

class UserchatModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  final String fcmToken;
  final String profilePic;
  final dynamic lastActive; // Can be FieldValue, Timestamp, or null

  UserchatModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    required this.fcmToken,
    required this.profilePic,
    this.lastActive,
  });

  factory UserchatModel.fromMap(Map<String, dynamic> map) {
    return UserchatModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      image: map['image'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      profilePic: map['profilePic'] ?? '',
      lastActive: map['lastActive'], // Handles Timestamp, String, or null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'fcmToken': fcmToken,
      'profilePic': profilePic,
      'lastActive': lastActive is Timestamp
          ? lastActive.toDate().toIso8601String()
          : null, // Convert Timestamp to string, ignore FieldValue
    };
  }

  // For Firestore writes, where FieldValue is needed
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'fcmToken': fcmToken,
      'profilePic': profilePic,
      'lastActive': lastActive ?? FieldValue.serverTimestamp(),
    };
  }
}