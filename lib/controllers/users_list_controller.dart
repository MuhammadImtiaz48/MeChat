import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/home_screen_controller.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersListController extends GetxController {
  final RxList<UserchatModel> filteredUsers = <UserchatModel>[].obs;
  final RxList<UserchatModel> _allUsers = <UserchatModel>[].obs;
  final RxBool loadingUsers = false.obs;
  final RxBool isSearching = false.obs;
  final RxString loggedInUserName = ''.obs;
  final TextEditingController searchController = TextEditingController();

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint('UsersListController: Initializing');
    }
    _loadLoggedInUserName();
    loadUsers();
    searchController.addListener(() => filterUsers(searchController.text));
  }

  @override
  void onClose() {
    if (kDebugMode) {
      debugPrint('UsersListController: Closing');
    }
    searchController.dispose();
    super.onClose();
  }

  Future<void> _loadLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInUserName.value = prefs.getString('user_name') ?? 'User';
  }

  Future<void> loadUsers() async {
    if (currentUserId.isEmpty) {
      if (kDebugMode) debugPrint('UsersListController: No current user UID');
      return;
    }

    loadingUsers.value = true;

    try {
      // Fetch all users except current user
      final usersQuery = FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .limit(100);

      if (kDebugMode) debugPrint('UsersListController: Loading users...');
      final usersSnapshot = await usersQuery.get().timeout(const Duration(seconds: 10));

      final List<UserchatModel> users = [];
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final user = UserchatModel.fromMap(userData);
        if (user.uid.isNotEmpty && user.uid != currentUserId) {
          users.add(user);
        }
      }

      // Sort users alphabetically
      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _allUsers.assignAll(users);
      filteredUsers.assignAll(users);

      if (kDebugMode) debugPrint('UsersListController: Loaded ${users.length} users');

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ UsersListController: Error loading users: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      Get.snackbar(
        'Error',
        'Failed to load users: ${e.toString().split('.').first}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      _allUsers.clear();
      filteredUsers.clear();
    } finally {
      loadingUsers.value = false;
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.assignAll(_allUsers.toList());
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = _allUsers
        .where((user) => user.name.toLowerCase().contains(lowerQuery) ||
                        user.email.toLowerCase().contains(lowerQuery))
        .toList();

    filteredUsers.assignAll(filtered);
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      clearSearch();
    }
  }

  void clearSearch() {
    searchController.clear();
    filteredUsers.assignAll(_allUsers.toList());
  }

  Future<void> startChatWithUser(UserchatModel user) async {
    try {
      // Check if chat already exists
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? existingChatId;
      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(user.uid)) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId != null) {
        // Navigate to existing chat
        Get.offNamed('/chat', arguments: {
          'user': user,
          'loggedInUserName': loggedInUserName.value,
        });
      } else {
        // Create new chat
        final chatDoc = FirebaseFirestore.instance.collection('chats').doc();
        await chatDoc.set({
          'participants': [currentUserId, user.uid],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': null,
          'lastMessageSenderId': '',
        });

        // Navigate to new chat
        Get.offNamed('/chat', arguments: {
          'user': user,
          'loggedInUserName': loggedInUserName.value,
        });

        // Refresh home screen to show the new chat
        final homeController = Get.find<HomeController>();
        await homeController.loadUsers();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('UsersListController: Error starting chat: $e');
      Get.snackbar(
        'Error',
        'Failed to start chat: ${e.toString().split('.').first}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}