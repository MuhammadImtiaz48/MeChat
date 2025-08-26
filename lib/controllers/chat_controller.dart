import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imtiaz/models/userchat.dart';

class UserChatController extends GetxController {
  final UserchatModel user;
  UserChatController({required this.user});

  var messages = <QueryDocumentSnapshot>[].obs;

  void listenMessages(String chatRoomId) {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs;
    });
  }
}
