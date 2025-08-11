import 'package:estate/UI_screens/models/massage_model.dart';
import 'package:get/get.dart';


class MessageController extends GetxController {
  var messages = <MessageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  void loadMessages() {
    messages.value = [
      MessageModel(
        sender: 'John',
        content: 'Hey! Are you free today?',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      MessageModel(
        sender: 'Anna',
        content: 'Please check the new property details.',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
      ),
      MessageModel(
        sender: 'Realix Bot',
        content: 'Your verification is complete!',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    ];
  }

  void markAsRead(int index) {
    messages[index].isRead = true;
    messages.refresh();
  }
}
