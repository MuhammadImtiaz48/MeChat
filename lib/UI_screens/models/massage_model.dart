class MessageModel {
  final String sender;
  final String content;
  final DateTime timestamp;
  bool isRead;

  MessageModel({
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });
}
