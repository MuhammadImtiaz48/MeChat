import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/userchat.dart';

class UserChatController extends GetxController {
  final UserchatModel user;

  UserChatController({required this.user});

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  var lastMessage = ''.obs;
  var isSeen = false.obs;
  var lastTime = Rxn<Timestamp>();

  @override
  void onInit() {
    super.onInit();
    _fetchLastMessage();
  }

  void _fetchLastMessage() {
    final chatId = getChatId(currentUserId, user.uid);

    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        lastMessage.value = data['text'] ?? '';
        isSeen.value = data['seen'] ?? false;
        lastTime.value = data['timestamp'];
      }
    });
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
