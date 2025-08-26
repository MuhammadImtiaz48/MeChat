import 'package:cloud_firestore/cloud_firestore.dart';

class UserchatModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  final String lastMessage;
  final DateTime? lastMessageTime;

  UserchatModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    this.lastMessage = '',
    this.lastMessageTime,
  });

  factory UserchatModel.fromMap(Map<String, dynamic> map) {
    return UserchatModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      image: map['image'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
    };
  }
}
