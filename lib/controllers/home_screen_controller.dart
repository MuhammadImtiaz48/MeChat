import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  final searchController = TextEditingController();
  final isSearching = false.obs;
  final filteredUsers = <UserchatModel>[].obs;
  final loadingUsers = true.obs;
  final isOnline = true.obs;
  final loggedInUserName = ''.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    _checkConnectivity();
  }

  @override
  void onClose() {
    searchController.dispose();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isOnline.value = !connectivityResult.contains(ConnectivityResult.none);
    if (!isOnline.value) Get.snackbar('Offline', 'Showing cached users', backgroundColor: Colors.orange, colorText: Colors.white);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = !results.contains(ConnectivityResult.none);
      if (!isOnline.value) Get.snackbar('Offline', 'Showing cached users', backgroundColor: Colors.orange, colorText: Colors.white);
      else loadUsers();
    });
  }

  Future<void> loadUsers() async {
    loadingUsers.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name') ?? '';
      loggedInUserName.value = cachedName.isNotEmpty ? cachedName : FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'User';

      if (isOnline.value) {
        final snapshot = await FirebaseFirestore.instance.collection('users').get();
        filteredUsers.value = snapshot.docs
            .map((doc) => UserchatModel.fromMap(doc.data()))
            .where((user) => user.uid != FirebaseAuth.instance.currentUser!.uid)
            .toList();
      } else {
        // Load cached users (implement caching logic if needed)
        filteredUsers.clear();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      loadingUsers.value = false;
    }
  }

  void filterUsers(String query) async {
    if (query.isEmpty) {
      loadUsers();
      return;
    }

    try {
      final lowerQuery = query.trim().toLowerCase();
      if (isOnline.value) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
            .where('nameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .get();
        filteredUsers.value = snapshot.docs
            .map((doc) => UserchatModel.fromMap(doc.data()))
            .where((user) => user.uid != FirebaseAuth.instance.currentUser!.uid)
            .toList();
      } else {
        filteredUsers.value = filteredUsers.where((user) => user.name.toLowerCase().contains(lowerQuery)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Search failed: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    loadUsers();
  }

  Future<void> logout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF075E54)))),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Get.offAllNamed('/dashboard');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}