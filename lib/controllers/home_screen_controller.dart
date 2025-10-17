import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  final RxList<UserchatModel> filteredUsers = <UserchatModel>[].obs;
  final RxList<UserchatModel> allUsers = <UserchatModel>[].obs;
  final RxList<UserchatModel> _allUsers = <UserchatModel>[].obs;
  final RxSet<String> deletedUserIds = <String>{}.obs;
  final RxBool loadingUsers = false.obs;
  final RxBool isSearching = false.obs;
  final RxString loggedInUserName = ''.obs;
  final RxBool isOnline = true.obs;
  final TextEditingController searchController = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<RemoteMessage>? _fcmForegroundSubscription;
  StreamSubscription<RemoteMessage>? _fcmBackgroundSubscription;
  CancelableOperation<void>? _loadUsersDebouncer;
  Timer? _debounceTimer;

  HomeController() {
    _loadUsersDebouncer = CancelableOperation<void>.fromFuture(Future.value());
  }

  Future<void> _loadDeletedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_user_ids') ?? [];
    deletedUserIds.assignAll(deletedIds.toSet());
    if (kDebugMode) debugPrint('HomeController: Loaded ${deletedUserIds.length} deleted user IDs');
  }


  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint('HomeController: Initializing at ${DateTime.now()}');
    }
    _loadDeletedUsers();
    _initializeConnectivity();
    _initializeFCM();
    searchController.addListener(() => filterUsers(searchController.text));
    ever(isOnline, (_) => loadUsers());
  }

  @override
  void onClose() {
    if (kDebugMode) {
      debugPrint('HomeController: Closing at ${DateTime.now()}');
    }
    _debounceTimer?.cancel();
    _loadUsersDebouncer?.cancel();
    _connectivitySubscription?.cancel();
    _fcmForegroundSubscription?.cancel();
    _fcmBackgroundSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> _initializeConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 15));
      isOnline.value = !result.contains(ConnectivityResult.none);
      if (kDebugMode) debugPrint('HomeController: Initial connectivity: ${isOnline.value ? "Online" : "Offline"}');
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final newOnline = !results.contains(ConnectivityResult.none);
        if (isOnline.value != newOnline) {
          isOnline.value = newOnline;
          if (kDebugMode) debugPrint('HomeController: Connectivity changed to: ${isOnline.value ? "Online" : "Offline"}');
          if (!isOnline.value) {
            if (kDebugMode) debugPrint('HomeController: Offline - skipping reload');
          } else {
            loadUsers();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ HomeController: Connectivity error: $e');
      isOnline.value = false;
      Get.snackbar('Error', 'Unable to check network connection', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _initializeFCM() async {
    final messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    if (kDebugMode) debugPrint('FCM: User granted permission: ${settings.authorizationStatus}');

    String? token = await messaging.getToken();
    if (token != null && FirebaseAuth.instance.currentUser != null) {
      if (kDebugMode) debugPrint('FCM: Saving token for UID: ${FirebaseAuth.instance.currentUser!.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'fcmToken': token}).catchError((e) {
        if (kDebugMode) debugPrint('FCM: Error saving token: $e');
      });
    }
    if (kDebugMode) debugPrint('FCM: FCM Token: $token');

    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isNotEmpty) {
      await messaging.subscribeToTopic('user_$currentUid');
      if (kDebugMode) debugPrint('FCM: Subscribed to topic: user_$currentUid');
    }

    _fcmForegroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('FCM: Received foreground message: ${message.notification?.title}');
      loadUsers();
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'New Message',
          message.notification!.body ?? 'You have a new message!',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    });

    _fcmBackgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('FCM: Opened from background message: ${message.notification?.title}');
      if (message.data.containsKey('chatId') && message.data['chatId'] != null) {
        Get.toNamed('/chat', arguments: {'chatId': message.data['chatId']});
      }
      loadUsers();
    });

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) debugPrint('FCM: App opened from terminated message: ${initialMessage.notification?.title}');
      if (initialMessage.data.containsKey('chatId') && initialMessage.data['chatId'] != null) {
        Get.toNamed('/chat', arguments: {'chatId': initialMessage.data['chatId']});
      }
      loadUsers();
    }
  }

  void _sortUsers(List<UserchatModel> users) {
    if (kDebugMode) {
      debugPrint('HomeController: Sorting ${users.length} users');
      for (var user in users) {
        debugPrint('User: ${user.name}, lastMessageTime: ${user.lastMessageTime}, unreadCount: ${user.unreadCount}');
      }
    }
    users.sort((a, b) {
      // First priority: Users with unread messages
      if (a.unreadCount > 0 && b.unreadCount == 0) {
        return -1; // a comes first (has unread messages)
      } else if (a.unreadCount == 0 && b.unreadCount > 0) {
        return 1; // b comes first (has unread messages)
      } else if (a.unreadCount > 0 && b.unreadCount > 0) {
        // Both have unread messages, sort by message time (most recent first)
        if (a.lastMessageTime != null && b.lastMessageTime != null) {
          final timeCompare = b.lastMessageTime!.compareTo(a.lastMessageTime!);
          if (timeCompare != 0) return timeCompare;
        }
        // If times are equal or one is null, sort by unread count (higher first)
        final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
        if (unreadCompare != 0) return unreadCompare;
      }

      // Second priority: Users with valid lastMessageTime (for users with no unread messages)
      if (a.lastMessageTime == null && b.lastMessageTime == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (a.lastMessageTime == null) {
        return 1; // b comes first (has a valid timestamp)
      } else if (b.lastMessageTime == null) {
        return -1; // a comes first (has a valid timestamp)
      }

      try {
        final timeA = a.lastMessageTime!;
        final timeB = b.lastMessageTime!;
        if (timeA == timeB) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return timeB.compareTo(timeA); // Descending order (most recent first)
      } catch (e) {
        if (kDebugMode) debugPrint('HomeController: Sorting error for ${a.name} vs ${b.name}: $e');
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    if (kDebugMode) {
      debugPrint('HomeController: Sorted users:');
      for (var user in users) {
        debugPrint('User: ${user.name}, lastMessageTime: ${user.lastMessageTime}, unreadCount: ${user.unreadCount}');
      }
    }
  }

  Future<void> loadUsers({bool cached = false}) async {
    await _loadUsersDebouncer?.cancel();
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _loadUsersDebouncer = CancelableOperation.fromFuture(_loadUsersInternal(cached: cached));
      await _loadUsersDebouncer!.valueOrCancellation();
    });
  }

  Future<void> _loadUsersInternal({bool cached = false}) async {
    if (!isOnline.value && !cached) {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsersJson = prefs.getString('cached_users');
      if (cachedUsersJson != null) {
        try {
          final List<dynamic> userMaps = jsonDecode(cachedUsersJson);
          final users = userMaps.map((map) => UserchatModel.fromMap(Map<String, dynamic>.from(map as Map))).toList();
          _sortUsers(users);
          _allUsers.assignAll(users);
          allUsers.assignAll(users);
          filteredUsers.assignAll(users);
          if (kDebugMode) debugPrint('HomeController: Loaded ${users.length} cached users');
        } catch (e) {
          if (kDebugMode) debugPrint('HomeController: Error decoding cached users: $e');
          Get.snackbar('Error', 'Failed to load cached users', backgroundColor: Colors.red, colorText: Colors.white);
          _allUsers.clear();
          filteredUsers.clear();
        }
      }
      loadingUsers.value = false;
      return;
    }

    loadingUsers.value = true;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      if (kDebugMode) debugPrint('HomeController: No current user UID - cannot load');
      loadingUsers.value = false;
      return;
    }

    if (kDebugMode) debugPrint('HomeController: Starting loadUsers for UID: $currentUid');

    try {
      // Step 1: Fetch all users from the 'users' collection (excluding current user)
      final usersQuery = FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUid)
          .limit(50);

      if (kDebugMode) debugPrint('HomeController: Executing users query...');
      final usersSnapshot = await usersQuery.get().timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('HomeController: Users query returned ${usersSnapshot.docs.length} documents');

      final List<UserchatModel> users = [];
      final Map<String, Map<String, dynamic>> allUserDataMap = <String, Map<String, dynamic>>{};

      // Store all user data
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userUid = userData['uid'] as String? ?? '';
        if (userUid.isEmpty || userUid == currentUid) continue;
        allUserDataMap[userUid] = userData;
        if (kDebugMode) debugPrint('HomeController: Mapped user data for UID: $userUid');
      }

      // Step 2: Fetch chats to get lastMessage and lastMessageTime for relevant users
      final chatsQuery = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUid)
          .limit(50);

      if (kDebugMode) debugPrint('HomeController: Executing chats query...');
      final chatSnapshot = await chatsQuery.get().timeout(const Duration(seconds: 20));
      if (kDebugMode) debugPrint('HomeController: Chats query returned ${chatSnapshot.docs.length} documents');

      final Map<String, Map<String, dynamic>> chatDataByOtherUid = <String, Map<String, dynamic>>{};
      for (var doc in chatSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.length < 2) {
          if (kDebugMode) debugPrint('HomeController: Skipping chat ${doc.id} - invalid participants: $participants');
          continue;
        }
        final otherUid = participants.firstWhere((uid) => uid != currentUid, orElse: () => '');
        if (otherUid.isEmpty) {
          if (kDebugMode) debugPrint('HomeController: Skipping chat ${doc.id} - no other UID found');
          continue;
        }
        chatDataByOtherUid[otherUid] = data;
        if (kDebugMode) debugPrint('HomeController: Found chat with other UID: $otherUid');
      }

      // Step 3: Combine user data with chat data
      for (var userUid in allUserDataMap.keys) {
        // Skip deleted users
        if (deletedUserIds.contains(userUid)) {
          if (kDebugMode) debugPrint('HomeController: Skipping deleted user $userUid');
          continue;
        }

        final userData = Map<String, dynamic>.from(allUserDataMap[userUid]!);
        final chatData = chatDataByOtherUid[userUid];

        if (chatData != null && chatData['lastMessageTime'] != null) {
          try {
            userData['lastMessageTime'] = chatData['lastMessageTime'] is Timestamp
                ? (chatData['lastMessageTime'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
          } catch (e) {
            if (kDebugMode) debugPrint('HomeController: Invalid lastMessageTime for $userUid: $e');
            userData['lastMessageTime'] = null;
          }
          if (chatData['lastMessage'] != null) {
            userData['lastMessage'] = chatData['lastMessage']?.toString() ?? '';
          }

          // Calculate unread count for this chat
          final chatId = chatData['chatId'] ?? _generateChatId(currentUid, userUid);
          final unreadCount = await _getUnreadCount(chatId, currentUid);
          userData['unreadCount'] = unreadCount;
        } else {
          userData['lastMessageTime'] = null;
          userData['lastMessage'] = '';
          userData['unreadCount'] = 0;
        }

        final user = UserchatModel.fromMap(userData);
        if (user.uid.isNotEmpty && !users.any((u) => u.uid == user.uid)) {
          users.add(user);
          if (kDebugMode) debugPrint('HomeController: Added user ${user.name} (${user.uid}) with lastMessageTime: ${user.lastMessageTime}, unreadCount: ${user.unreadCount}');
        }
      }

      _sortUsers(users);
      _allUsers.assignAll(users);
      filteredUsers.assignAll(users);
      if (kDebugMode) debugPrint('HomeController: Successfully loaded ${users.length} sorted user cards');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_users', jsonEncode(users.map((u) => u.toMap()).toList()));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ HomeController: Error in loadUsers: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('HomeController: PERMISSION_DENIED - Update Firestore rules to allow read/write on "chats" and "users"');
        Get.snackbar('Error', 'Permission denied. Check Firestore rules.', backgroundColor: Colors.red, colorText: Colors.white);
      } else if (e is TimeoutException) {
        Get.snackbar('Error', 'Request timed out. Check your connection.', backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to load users: ${e.toString().split('.').first}', backgroundColor: Colors.red, colorText: Colors.white);
      }
      _allUsers.clear();
      filteredUsers.clear();
    } finally {
      loadingUsers.value = false;
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      if (kDebugMode) debugPrint('HomeController: Search cleared - resetting to full list');
      filteredUsers.assignAll(_allUsers.toList());
      return;
    }

    final lowerQuery = query.toLowerCase();
    if (kDebugMode) debugPrint('HomeController: Filtering for query: $lowerQuery');
    final allUsers = _allUsers.toList();
    final filtered = allUsers
        .where((user) => user.name.toLowerCase().contains(lowerQuery))
        .toList();

    _sortUsers(filtered);
    filteredUsers.assignAll(filtered);
    if (kDebugMode) debugPrint('HomeController: Filtered to ${filtered.length} users');
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    if (kDebugMode) debugPrint('HomeController: Clearing search');
    filteredUsers.assignAll(_allUsers.toList());
  }

  String _generateChatId(String uid1, String uid2) {
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  Future<int> _getUnreadCount(String chatId, String currentUserId) async {
    try {
      // Get all messages from other users first, then filter for unseen ones
      // This avoids the compound index requirement
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      // Filter for unseen messages in memory
      final unseenMessages = messagesSnapshot.docs
          .where((doc) => !(doc.data()['seen'] ?? false))
          .toList();

      return unseenMessages.length;
    } catch (e) {
      if (kDebugMode) debugPrint('HomeController: Error getting unread count for $chatId: $e');
      return 0;
    }
  }
}