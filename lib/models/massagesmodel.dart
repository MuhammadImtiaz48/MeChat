import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final bool seen;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.seen = false,
  });

  /// Factory constructor with null checks and default fallbacks
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      seen: data['seen'] ?? false,
    );
  }

  /// Convert model to Firestore-compatible map
  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type.toString().split('.').last,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        'seen': seen,
      };
}
