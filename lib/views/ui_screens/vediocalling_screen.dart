// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:imtiaz/models/userchat.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:imtiaz/firebase_Services/call_services.dart';
// import 'package:imtiaz/firebase_Services/notification_services.dart';

// class ChatScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverEmail;
//   final UserchatModel user;

//   const ChatScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverEmail,
//     required this.user,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String get currentUserId => _auth.currentUser!.uid;

//   String get chatRoomId =>
//       currentUserId.hashCode <= widget.receiverId.hashCode
//           ? "${currentUserId}_${widget.receiverId}"
//           : "${widget.receiverId}_${currentUserId}";

//   @override
//   void initState() {
//     super.initState();
//     _listenForIncomingMessages();
//   }

//   void _listenForIncomingMessages() {
//     _firestore
//         .collection("chats")
//         .doc(chatRoomId)
//         .collection("messages")
//         .orderBy("timestamp", descending: true)
//         .snapshots()
//         .listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           var data = change.doc.data();
//           if (data != null && data["senderId"] != currentUserId) {
//             // Show local notification for incoming messages
//             LocalNotificationService.showNotification(
//               title: widget.receiverName,
//               body: data['message'] ?? "New message",
//             );
//           }
//         }
//       }
//     });
//   }

//   Future<void> sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     String message = _messageController.text.trim();
//     _messageController.clear();

//     await _firestore
//         .collection("chats")
//         .doc(chatRoomId)
//         .collection("messages")
//         .add({
//       "senderId": currentUserId,
//       "receiverId": widget.receiverId,
//       "message": message,
//       "timestamp": FieldValue.serverTimestamp(),
//       "seen": false,
//     });
//   }

//   Future<void> deleteMessage(String docId) async {
//     await _firestore
//         .collection("chats")
//         .doc(chatRoomId)
//         .collection("messages")
//         .doc(docId)
//         .delete();
//   }

//   void markMessagesAsSeen(QuerySnapshot snapshot) async {
//     for (var doc in snapshot.docs) {
//       if (doc["receiverId"] == currentUserId && doc["seen"] == false) {
//         await doc.reference.update({"seen": true});
//       }
//     }
//   }

//   void startVideoCall() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ZegoUIKitPrebuiltCall(
//           appID: 116174848,
//           appSign:
//               '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679',
//           userID: currentUserId,
//           userName: _auth.currentUser!.displayName ?? "User",
//           callID: chatRoomId,
//           config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
//         ),
//       ),
//     );
//   }

//   void startAudioCall() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ZegoUIKitPrebuiltCall(
//           appID: 116174848,
//           appSign:
//               '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679',
//           userID: currentUserId,
//           userName: _auth.currentUser!.displayName ?? "User",
//           callID: chatRoomId,
//           config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.receiverName),
//         actions: [
//           IconButton(icon: const Icon(Icons.videocam), onPressed: startVideoCall),
//           IconButton(icon: const Icon(Icons.call), onPressed: startAudioCall),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection("chats")
//                   .doc(chatRoomId)
//                   .collection("messages")
//                   .orderBy("timestamp", descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 var messages = snapshot.data!.docs;
//                 markMessagesAsSeen(snapshot.data!);

//                 if (messages.isEmpty) {
//                   return const Center(child: Text("No messages yet"));
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     var msg = messages[index];
//                     bool isMe = msg["senderId"] == currentUserId;

//                     return GestureDetector(
//                       onLongPress: () {
//                         if (isMe) {
//                           showDialog(
//                             context: context,
//                             builder: (ctx) => AlertDialog(
//                               title: const Text("Delete Message?"),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(ctx),
//                                   child: const Text("Cancel"),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     deleteMessage(msg.id);
//                                     Navigator.pop(ctx);
//                                   },
//                                   child: const Text("Delete"),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//                       },
//                       child: Align(
//                         alignment: isMe
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(
//                               vertical: 4, horizontal: 8),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isMe ? Colors.blue : Colors.grey[300],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg["message"],
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: isMe ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     msg["timestamp"] == null
//                                         ? ""
//                                         : (msg["timestamp"] as Timestamp)
//                                             .toDate()
//                                             .toLocal()
//                                             .toString()
//                                             .substring(11, 16),
//                                     style: TextStyle(
//                                         fontSize: 10,
//                                         color: isMe
//                                             ? Colors.white70
//                                             : Colors.black54),
//                                   ),
//                                   if (isMe) ...[
//                                     const SizedBox(width: 6),
//                                     Icon(
//                                       msg["seen"]
//                                           ? Icons.done_all
//                                           : Icons.check,
//                                       size: 16,
//                                       color: msg["seen"]
//                                           ? Colors.green
//                                           : Colors.white,
//                                     ),
//                                   ]
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: const InputDecoration(
//                       hintText: "Type a message...",
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
