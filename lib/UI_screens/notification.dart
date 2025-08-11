// ... your imports
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:estate/UI_screens/massage_reading.dart';
import 'package:estate/UI_screens/nonotification.dart';
import 'package:estate/controllers/notification_controoler.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationController());

    // Delay navigation to allow widget to fully build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.notifications.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const NoNotificationScreen(),
          ),
        );
      }
    });
  }

  String formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all as read',
            onPressed: controller.markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear all',
            onPressed: () {
              controller.clearAll();
              Future.delayed(const Duration(milliseconds: 200), () {
                if (controller.notifications.isEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NoNotificationScreen()),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Obx(() {
          final notifications = controller.notifications;
          if (notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = notifications[index];

              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.notifications, color: Colors.blue),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 14.sp),
                ),
                trailing: SizedBox(
                  height: 60.h,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!item.isRead)
                        Icon(Icons.circle, size: 12.sp, color: Colors.blue.shade600),
                      Text(
                        formatTime(item.dateTime),
                        style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.deleteNotification(index);
                          if (controller.notifications.isEmpty) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const NoNotificationScreen()),
                            );
                          }
                        },
                        child: const Icon(Icons.delete, size: 20, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  controller.markAsRead(index);
                  if (item.type == 'message' && item.messageContent != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageDetailScreen(message: item.messageContent!),
                      ),
                    );
                  }
                },
              );
            },
          );
        }),
      ),
    );
  }
}
