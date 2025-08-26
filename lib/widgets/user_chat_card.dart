import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/views/ui_screens/chat_screen.dart';
import 'package:imtiaz/controllers/chat_controller.dart';

class UserChatCard extends StatelessWidget {
  final UserchatModel user;
  final UserChatController controller;

  const UserChatCard({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller to listen for messages
    controller.listenMessages(user.uid);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              user: user,
              receiverId: user.uid,
              receiverName: user.name,
              receiverEmail: user.email, receiverFcmToken: '',
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Obx(() {
          // Get the latest message
          final lastMsgDoc = controller.messages.isNotEmpty
              ? controller.messages.first
              : null;

          final lastMessage = lastMsgDoc != null
              ? lastMsgDoc["message"] ?? ""
              : "";

          final lastTime = lastMsgDoc != null && lastMsgDoc["timestamp"] != null
              ? (lastMsgDoc["timestamp"] as Timestamp).toDate()
              : null;

          final isSeen = lastMsgDoc != null
              ? lastMsgDoc["seen"] ?? false
              : false;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.image),
              radius: 26,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage.isNotEmpty ? lastMessage : "No messages yet",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lastTime != null)
                  Text(
                    _formatTime(lastTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                if (lastMessage.isNotEmpty)
                  Icon(
                    isSeen ? Icons.done_all : Icons.check,
                    size: 18,
                    color: isSeen ? Colors.blue : Colors.grey,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Format time as HH:mm
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
