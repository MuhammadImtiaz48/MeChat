import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/ui_screens/chat_screen.dart';
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
        );
      },
      child: Card(
        child: Obx(() => ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.image),
                radius: 26,
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                controller.lastMessage.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.lastMessage.isNotEmpty &&
                      controller.lastTime.value != null)
                    Text(
                      controller.formatTime(controller.lastTime.value),
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (controller.lastMessage.isNotEmpty)
                    Icon(
                      controller.isSeen.value
                          ? Icons.done_all
                          : Icons.check,
                      size: 18,
                      color:
                          controller.isSeen.value ? Colors.blue : Colors.grey,
                    ),
                ],
              ),
            )),
      ),
    );
  }
}
