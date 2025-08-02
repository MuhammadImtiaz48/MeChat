// ChatScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imtiaz/models/userchat.dart';

class ChatScreen extends StatefulWidget {
  final UserchatModel user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String getChatId(String id1, String id2) =>
      id1.hashCode <= id2.hashCode ? '${id1}_$id2' : '${id2}_$id1';

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatId = getChatId(currentUserId, widget.user.uid);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId(currentUserId, widget.user.uid);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user.image),
            ),
            const SizedBox(width: 8),
            Text(widget.user.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                for (final doc in messages) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['senderId'] != currentUserId &&
                      (data['seen'] == null || data['seen'] == false)) {
                    doc.reference.update({'seen': true});
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final time = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp.toDate())
                        : '';

                    final isLastMessage = index == messages.length - 1;
                    final seen = data['seen'] ?? false;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.lightGreen[200] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(data['text'] ?? '',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                                if (isMe && isLastMessage) ...[
                                  const SizedBox(width: 5),
                                  Icon(
                                    seen ? Icons.done_all : Icons.check,
                                    size: 18,
                                    color: seen ? Colors.blue : Colors.grey,
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type your message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
