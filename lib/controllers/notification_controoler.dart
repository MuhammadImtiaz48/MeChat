import 'package:estate/UI_screens/models/notification_model.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void loadNotifications() {
    notifications.value = [
      NotificationModel(
        title: 'New Message',
        subtitle: 'You received a message from John.',
        dateTime: DateTime.now().subtract(Duration(minutes: 5)),
        messageContent: 'Hi! Let\'s meet tomorrow.',
        type: 'message',
      ),
      NotificationModel(
        title: 'Price Drop Alert',
        subtitle: 'Price dropped for a property.',
        dateTime: DateTime.now().subtract(Duration(hours: 3)),
        type: 'alert',
      ),
      NotificationModel(
        title: 'App Update',
        subtitle: 'Version 2.0 available.',
        dateTime: DateTime.now().subtract(Duration(days: 1)),
        type: 'update',
      ),
    ];

    notifications.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  void markAsRead(int index) {
    final item = notifications[index];
    if (!item.isRead) {
      notifications[index] = item.copyWith(isRead: true);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
  }

  void deleteNotification(int index) {
    notifications.removeAt(index);
  }

  void clearAll() {
    notifications.clear();
  }
}
