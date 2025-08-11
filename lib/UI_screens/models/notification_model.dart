class NotificationModel {
  final String title;
  final String subtitle;
  final DateTime dateTime;
   bool isRead;
  final String? messageContent;
  final String? type;

  NotificationModel({
    required this.title,
    required this.subtitle,
    required this.dateTime,
    this.isRead = false,
    this.messageContent,
    this.type,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      title: title,
      subtitle: subtitle,
      dateTime: dateTime,
      isRead: isRead ?? this.isRead,
      messageContent: messageContent,
      type: type,
    );
  }
}
