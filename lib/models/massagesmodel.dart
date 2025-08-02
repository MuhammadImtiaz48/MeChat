import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  /// Factory constructor with null checks and default fallbacks
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert model to Firestore-compatible map
  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
