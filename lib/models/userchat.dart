import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class UserchatModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  final String fcmToken;
  final String profilePic;
  final DateTime? lastActive; // Parsed from Timestamp or String
  final DateTime? lastMessageTime; // For chat sorting, parsed from Timestamp or String

  UserchatModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    required this.fcmToken,
    required this.profilePic,
    this.lastActive,
    this.lastMessageTime,
  });

  factory UserchatModel.fromMap(Map<String, dynamic> map) {
    // Validate required fields with fallbacks
    final String uid = map['uid']?.toString().trim() ?? '';
    final String name = map['name']?.toString().trim().isNotEmpty == true
        ? map['name'].toString().trim()
        : 'Unknown';
    final String email = map['email']?.toString().trim() ?? '';
    final String image = map['image']?.toString().trim() ?? '';
    final String fcmToken = map['fcmToken']?.toString().trim() ?? '';
    final String profilePic = map['profilePic']?.toString().trim() ?? '';

    // Parse lastActive
    DateTime? lastActive;
    if (map['lastActive'] != null) {
      try {
        if (map['lastActive'] is Timestamp) {
          lastActive = (map['lastActive'] as Timestamp).toDate();
        } else if (map['lastActive'] is String) {
          lastActive = DateTime.tryParse(map['lastActive'] as String);
        } else {
          if (kDebugMode) {
            debugPrint('UserchatModel: Invalid lastActive format for uid=$uid: ${map['lastActive'].runtimeType}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('UserchatModel: Error parsing lastActive for uid=$uid: $e');
        }
      }
    }

    // Parse lastMessageTime
    DateTime? lastMessageTime;
    if (map['lastMessageTime'] != null) {
      try {
        if (map['lastMessageTime'] is Timestamp) {
          lastMessageTime = (map['lastMessageTime'] as Timestamp).toDate();
        } else if (map['lastMessageTime'] is String) {
          lastMessageTime = DateTime.tryParse(map['lastMessageTime'] as String);
        } else {
          if (kDebugMode) {
            debugPrint('UserchatModel: Invalid lastMessageTime format for uid=$uid: ${map['lastMessageTime'].runtimeType}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('UserchatModel: Error parsing lastMessageTime for uid=$uid: $e');
        }
      }
    }

    // Validate uid
    if (uid.isEmpty) {
      if (kDebugMode) {
        debugPrint('UserchatModel: Warning: Empty UID in map=$map');
      }
    }

    return UserchatModel(
      uid: uid,
      name: name,
      email: email,
      image: image,
      fcmToken: fcmToken,
      profilePic: profilePic,
      lastActive: lastActive,
      lastMessageTime: lastMessageTime,
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
      'lastActive': lastActive?.toIso8601String(), // Convert to ISO 8601 string for JSON
      'lastMessageTime': lastMessageTime?.toIso8601String(), // Convert to ISO 8601 string for JSON
    };
  }

  // For Firestore writes, where FieldValue is needed for new timestamps
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'fcmToken': fcmToken,
      'profilePic': profilePic,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
    };
  }

  // Utility method for updating fields
  UserchatModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? image,
    String? fcmToken,
    String? profilePic,
    DateTime? lastActive,
    DateTime? lastMessageTime,
  }) {
    return UserchatModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      fcmToken: fcmToken ?? this.fcmToken,
      profilePic: profilePic ?? this.profilePic,
      lastActive: lastActive ?? this.lastActive,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  @override
  String toString() {
    return 'UserchatModel(uid: $uid, name: $name, email: $email, lastActive: $lastActive, lastMessageTime: $lastMessageTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserchatModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}