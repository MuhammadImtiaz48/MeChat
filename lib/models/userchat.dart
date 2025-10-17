import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class UserchatModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  final String fcmToken;
  final String profilePic;
  final DateTime? lastActive;
  final DateTime? lastMessageTime;
  final String lastMessage;
  final int unreadCount;

  UserchatModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    required this.fcmToken,
    required this.profilePic,
    this.lastActive,
    this.lastMessageTime,
    this.lastMessage = '',
    this.unreadCount = 0,
  });

  factory UserchatModel.fromMap(Map<String, dynamic> map) {
    final String uid = map['uid']?.toString().trim() ?? '';
    final String name = (map['name']?.toString().trim().isNotEmpty == true)
        ? map['name'].toString().trim()
        : 'Unknown';
    final String email = map['email']?.toString().trim() ?? '';
    final String image = map['image']?.toString().trim() ?? '';
    final String fcmToken = map['fcmToken']?.toString().trim() ?? '';
    final String profilePic = map['profilePic']?.toString().trim() ?? '';

    DateTime? lastActive;
    if (map['lastActive'] != null) {
      try {
        if (map['lastActive'] is Timestamp) {
          lastActive = (map['lastActive'] as Timestamp).toDate();
        } else if (map['lastActive'] is String) {
          lastActive = DateTime.tryParse(map['lastActive']);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error parsing lastActive for uid=$uid: $e');
      }
    }

    DateTime? lastMessageTime;
    if (map['lastMessageTime'] != null) {
      try {
        if (map['lastMessageTime'] is Timestamp) {
          lastMessageTime = (map['lastMessageTime'] as Timestamp).toDate();
        } else if (map['lastMessageTime'] is String) {
          lastMessageTime = DateTime.tryParse(map['lastMessageTime']);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error parsing lastMessageTime for uid=$uid: $e');
      }
    }

    final String lastMessage = map['lastMessage']?.toString() ?? '';
    final int unreadCount = map['unreadCount'] ?? 0;

    return UserchatModel(
      uid: uid,
      name: name,
      email: email,
      image: image,
      fcmToken: fcmToken,
      profilePic: profilePic,
      lastActive: lastActive,
      lastMessageTime: lastMessageTime,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
    );
  }

  /// ✅ Never sends empty fields to Firestore
  Map<String, dynamic> toFirestore({bool updateOnly = false}) {
    final Map<String, dynamic> data = {};

    // Only include fields that have meaningful values (avoids overwriting)
    if (uid.isNotEmpty) data['uid'] = uid;
    if (name.isNotEmpty) data['name'] = name;
    if (email.isNotEmpty) data['email'] = email;
    if (image.isNotEmpty) data['image'] = image;
    if (fcmToken.isNotEmpty) data['fcmToken'] = fcmToken;
    if (profilePic.isNotEmpty) data['profilePic'] = profilePic;

    // Add timestamps
    if (lastActive != null) {
      data['lastActive'] = Timestamp.fromDate(lastActive!);
    } else if (!updateOnly) {
      data['lastActive'] = FieldValue.serverTimestamp();
    }

    if (lastMessageTime != null) {
      data['lastMessageTime'] = Timestamp.fromDate(lastMessageTime!);
    }

    return data;
  }

  /// For local or JSON conversions
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'fcmToken': fcmToken,
      'profilePic': profilePic,
      'lastActive': lastActive?.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }

  UserchatModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? image,
    String? fcmToken,
    String? profilePic,
    DateTime? lastActive,
    DateTime? lastMessageTime,
    String? lastMessage,
    int? unreadCount,
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
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() =>
      'UserchatModel(uid: $uid, name: $name, profilePic: $profilePic, lastActive: $lastActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserchatModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}
