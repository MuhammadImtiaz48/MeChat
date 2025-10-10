import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/firebase_Services/notification_services.dart';
import 'package:imtiaz/models/userchat.dart';

class ChatController extends GetxController {
  final UserchatModel user;
  final String loggedInUserName;
  final RxBool isOnline = true.obs;
  final RxString lastSeen = ''.obs;
  final RxString myName = ''.obs;
  final RxList<Map<String, dynamic>> cachedMessages = <Map<String, dynamic>>[].obs;
  final RxBool isSending = false.obs;
  late String chatRoomId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _lastSeenSubscription;
  StreamSubscription<DocumentSnapshot>? _myNameSubscription;

  ChatController({required this.user, required this.loggedInUserName}) {
    myName.value = loggedInUserName.isNotEmpty && loggedInUserName.toLowerCase() != 'unknown' ? loggedInUserName : 'User';
    chatRoomId = _generateChatRoomId(_auth.currentUser!.uid, user.uid);
    listenToLastSeen();
    _loadCachedMessages();
    _startMyNameListener();
    if (kDebugMode) {
      debugPrint('✅ ChatController: Initialized for user=${user.uid}, chatRoomId=$chatRoomId');
    }
  }

  String _generateChatRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}-${ids[1]}';
  }

  String _formatLastSeen(Timestamp? lastActive) {
    if (lastActive == null) return 'Last seen unknown';
    final lastActiveDate = lastActive.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastActiveDate);
    if (difference.inSeconds < 60) {
      return 'Online';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Last seen ${lastActiveDate.day}/${lastActiveDate.month}/${lastActiveDate.year}';
    }
  }

  Future<void> _cacheLastSeen(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_${user.uid}', value);
      if (kDebugMode) {
        debugPrint('✅ ChatController: Cached last seen: $value for user=${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Error caching last seen: $e');
      }
    }
  }

  Future<void> _loadCachedLastSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLastSeen = prefs.getString('last_seen_${user.uid}') ?? 'Offline';
      lastSeen.value = cachedLastSeen;
      if (kDebugMode) {
        debugPrint('✅ ChatController: Loaded cached last seen: $cachedLastSeen for user=${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Error loading cached last seen: $e');
      }
      lastSeen.value = 'Offline';
    }
  }

  void _startMyNameListener() {
    final user = _auth.currentUser;
    if (user == null) {
      myName.value = loggedInUserName.isNotEmpty && loggedInUserName.toLowerCase() != 'unknown' ? loggedInUserName : 'User';
      return;
    }

    _myNameSubscription?.cancel();
    _myNameSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final userName = doc['name']?.toString().trim() ?? '';
        myName.value = userName.isNotEmpty && userName.toLowerCase() != 'unknown' ? userName : (user.email?.split('@')[0] ?? 'User');
        if (kDebugMode) {
          debugPrint('✅ ChatController: Updated myName: ${myName.value} for uid=${user.uid}');
        }
      } else {
        myName.value = user.email?.split('@')[0] ?? 'User';
        if (kDebugMode) {
          debugPrint('✅ ChatController: Set fallback myName: ${myName.value} for uid=${user.uid}');
        }
      }
    }, onError: (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: My name listener error: $e');
      }
      myName.value = loggedInUserName.isNotEmpty && loggedInUserName.toLowerCase() != 'unknown' ? loggedInUserName : 'User';
    });
  }

  void listenToLastSeen() {
    if (!isOnline.value) {
      _loadCachedLastSeen();
      return;
    }
    _lastSeenSubscription?.cancel();
    _lastSeenSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      try {
        if (snapshot.exists) {
          final lastActive = snapshot.data()!['lastActive'] as Timestamp?;
          lastSeen.value = _formatLastSeen(lastActive);
          _cacheLastSeen(lastSeen.value);
          if (kDebugMode) {
            debugPrint('✅ ChatController: Updated last seen: ${lastSeen.value} for user=${user.uid}');
          }
        } else {
          lastSeen.value = 'Last seen unknown';
          _cacheLastSeen(lastSeen.value);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatController: Error processing last seen stream: $e');
        }
        lastSeen.value = 'Last seen unknown';
        _cacheLastSeen(lastSeen.value);
      }
    }, onError: (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Last seen stream error: $e');
      }
      lastSeen.value = 'Last seen unavailable';
      _cacheLastSeen(lastSeen.value);
    });
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('messages_$chatRoomId') ?? '[]';
      final List<dynamic> messages = jsonDecode(cachedData);
      cachedMessages.assignAll(messages.map((m) => Map<String, dynamic>.from(m)).toList());
      if (kDebugMode) {
        debugPrint('✅ ChatController: Loaded ${cachedMessages.length} cached messages for $chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Error loading cached messages: $e');
      }
    }
  }

  Future<void> cacheMessages(List<Map<String, dynamic>> messages) async {
    try {
      final jsonMessages = messages.map((msg) {
        return {
          ...msg,
          'timestamp': msg['timestamp'] is Timestamp
              ? (msg['timestamp'] as Timestamp).toDate().toIso8601String()
              : msg['timestamp'] is DateTime
                  ? (msg['timestamp'] as DateTime).toIso8601String()
                  : msg['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
        };
      }).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('messages_$chatRoomId', jsonEncode(jsonMessages));
      cachedMessages.assignAll(jsonMessages);
      if (kDebugMode) {
        debugPrint('✅ ChatController: Cached ${jsonMessages.length} messages for $chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Error caching messages: $e');
      }
    }
  }

  Future<String?> _getReceiverFcmToken() async {
    for (int i = 0; i < 3; i++) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        if (userDoc.exists) {
          final fcmToken = userDoc.data()!['fcmToken']?.toString();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('✅ ChatController: Retrieved receiver FCM token for user=${user.uid}');
            }
            return fcmToken;
          }
        }
        if (kDebugMode) {
          debugPrint('⚠️ ChatController: No valid FCM token found for user=${user.uid}');
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatController: Error fetching receiver FCM token (attempt ${i + 1}): $e');
        }
        if (i == 2) {
          return null;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || !isOnline.value) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Message empty or offline, cannot send');
      }
      Get.snackbar(
        'Error',
        isOnline.value ? 'Message cannot be empty' : 'You are offline',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10.r,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
        titleText: Text(
          'Error',
          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        messageText: Text(
          isOnline.value ? 'Message cannot be empty' : 'You are offline',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
        ),
      );
      return;
    }
    isSending.value = true;
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }
      final receiverFcmToken = await _getReceiverFcmToken();
      for (int i = 0; i < 3; i++) {
        try {
          final msgData = {
            'senderId': currentUser.uid,
            'receiverId': user.uid,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'seen': false,
          };
          if (kDebugMode) {
            debugPrint('ChatController: Sending message to Firestore: $msgData');
          }
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .collection('messages')
              .add(msgData)
              .timeout(const Duration(seconds: 10));
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .set({
                'lastMessage': message,
                'lastMessageTime': FieldValue.serverTimestamp(),
                'participants': [currentUser.uid, user.uid],
                'typing_${user.uid}': false,
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 10));
          final cachedMsg = {
            'senderId': msgData['senderId'],
            'receiverId': msgData['receiverId'],
            'message': msgData['message'],
            'timestamp': DateTime.now().toIso8601String(),
            'seen': false,
          };
          cachedMessages.insert(0, cachedMsg);
          await cacheMessages(cachedMessages.toList());

          if (receiverFcmToken != null) {
            final success = await NotificationService.sendPushNotification(
              targetToken: receiverFcmToken,
              title: myName.value.isNotEmpty ? myName.value : 'User',
              body: message.length > 50 ? '${message.substring(0, 47)}...' : message,
              payload: {
                'type': 'message',
                'chatId': user.uid,
                'senderId': currentUser.uid,
                'senderName': myName.value.isNotEmpty ? myName.value : 'User',
              }, type: '', senderId: '', chatId: '', senderName: '', callType: '', callId: '', data: {},
            );
            if (success) {
              if (kDebugMode) {
                debugPrint('✅ ChatController: Sent message notification to receiver=${user.uid}');
              }
            } else {
              if (kDebugMode) {
                debugPrint('⚠️ ChatController: Failed to send message notification to receiver=${user.uid}');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ ChatController: No FCM token for receiver=${user.uid}, message notification skipped');
            }
          }

          return;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ ChatController: Error sending message (attempt ${i + 1}): $e');
          }
          if (i == 2) {
            rethrow;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatController: Error sending message: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to send message: Network error',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10.r,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
        titleText: Text(
          'Error',
          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        messageText: Text(
          'Failed to send message: Network error',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
        ),
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> markMessagesSeen() async {
    if (!isOnline.value) {
      if (kDebugMode) {
        debugPrint('⚠️ ChatController: Offline, cannot mark messages as seen');
      }
      return;
    }
    for (int i = 0; i < 3; i++) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .where('senderId', isEqualTo: user.uid)
            .where('seen', isEqualTo: false)
            .get()
            .timeout(const Duration(seconds: 10));
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'seen': true});
        }
        await batch.commit().timeout(const Duration(seconds: 10));
        final updatedMessages = cachedMessages.map((msg) {
          if (msg['senderId'] == user.uid && !(msg['seen'] ?? false)) {
            return {...msg, 'seen': true};
          }
          return msg;
        }).toList();
        await cacheMessages(updatedMessages);
        if (kDebugMode) {
          debugPrint('✅ ChatController: Marked messages as seen for $chatRoomId');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatController: Error marking messages seen (attempt ${i + 1}): $e');
        }
        if (i == 2) {
          Get.snackbar(
            'Error',
            'Failed to mark messages as seen: Network error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            borderRadius: 10.r,
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 3),
            titleText: Text(
              'Error',
              style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            messageText: Text(
              'Failed to mark messages as seen: Network error',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> handleTypingStatus(String text, bool hasFocus) async {
    if (!isOnline.value) {
      if (kDebugMode) {
        debugPrint('⚠️ ChatController: Offline, cannot update typing status');
      }
      return;
    }
    for (int i = 0; i < 3; i++) {
      try {
        final isTyping = text.isNotEmpty && hasFocus;
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .set({
              'typing_${_auth.currentUser!.uid}': isTyping,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        if (kDebugMode) {
          debugPrint('✅ ChatController: Updated typing status: $isTyping');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatController: Error updating typing status (attempt ${i + 1}): $e');
        }
        if (i == 2) {
          Get.snackbar(
            'Error',
            'Failed to update typing status: Network error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            borderRadius: 10.r,
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 3),
            titleText: Text(
              'Error',
              style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            messageText: Text(
              'Failed to update typing status: Network error',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> startCall({required bool isVideo}) async {
    final appController = Get.find<AppController>();
    if (!appController.isZegoInitialized.value) {
      Get.snackbar(
        'Error',
        'Call service not initialized',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10.r,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
        titleText: Text(
          'Error',
          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        messageText: Text(
          'Call service not initialized',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
        ),
      );
      return;
    }
    if (!_auth.currentUser!.uid.isNotEmpty || !user.uid.isNotEmpty) {
      Get.snackbar(
        'Error',
        'Invalid user IDs for call',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10.r,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
        titleText: Text(
          'Error',
          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        messageText: Text(
          'Invalid user IDs for call',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
        ),
      );
      return;
    }
    final receiverFcmToken = await _getReceiverFcmToken();
    for (int i = 0; i < 3; i++) {
      try {
        if (kDebugMode) {
          debugPrint('ChatController: Starting ${isVideo ? 'video' : 'voice'} call with ${user.uid}');
        }
        if (receiverFcmToken != null) {
          final success = await NotificationService.sendPushNotification(
            targetToken: receiverFcmToken,
            title: isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
            body: '${myName.value.isNotEmpty ? myName.value : 'User'} is calling you',
            payload: {
              'type': 'call',
              'chatId': user.uid,
              'senderId': _auth.currentUser!.uid,
              'senderName': myName.value.isNotEmpty ? myName.value : 'User',
              'callId': chatRoomId,
              'callType': isVideo ? 'video' : 'voice',
            }, type: '', senderId: '', chatId: '', senderName: '', callType: '', callId: '', data: {},
          );
          if (success) {
            if (kDebugMode) {
              debugPrint('✅ ChatController: Sent call notification to receiver=${user.uid}');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ ChatController: Failed to send call notification to receiver=${user.uid}');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ ChatController: No FCM token for receiver=${user.uid}, call notification skipped');
          }
        }

        Get.to(() => ZegoUIKitPrebuiltCall(
              appID: 116174848,
              appSign: '07f8d98822d54bc39ffc058f2c0a2b638930ba0c37156225bac798ae0f90f679',
              userID: _auth.currentUser!.uid,
              userName: myName.value.isNotEmpty ? myName.value : 'User',
              callID: chatRoomId,
              config: isVideo
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
            ));
        if (kDebugMode) {
          debugPrint('✅ ChatController: Navigated to ${isVideo ? 'video' : 'voice'} call screen');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatController: Error starting ${isVideo ? 'video' : 'voice'} call (attempt ${i + 1}): $e');
        }
        if (i == 2) {
          Get.snackbar(
            'Error',
            'Failed to start call: Network error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            borderRadius: 10.r,
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 3),
            titleText: Text(
              'Error',
              style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            messageText: Text(
              'Failed to start call: Network error',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  void onClose() {
    if (kDebugMode) {
      debugPrint('ChatController: Disposing for $chatRoomId');
    }
    _lastSeenSubscription?.cancel();
    _myNameSubscription?.cancel();
    super.onClose();
  }
}