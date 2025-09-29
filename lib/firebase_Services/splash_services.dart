import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:imtiaz/main.dart';

class SplashServices {
  Future<void> checkLoginStatus(BuildContext context) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      // Simulate a brief delay for splash screen visibility
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!context.mounted) {
        debugPrint("⚠️ Context not mounted, aborting navigation");
        return;
      }

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user != null) {
        String userName = await _getUserName(user, isOnline).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint("⚠️ User name fetch timed out, using fallback");
            return user.displayName?.trim() ??
                user.email?.split('@')[0] ??
                'User-${user.uid.substring(0, 6)}';
          },
        );
        debugPrint("✅ User logged in: ${user.uid}, name: $userName");
        if (context.mounted) {
          Get.offAll(
            () => HomeScreen(userName: userName),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 300),
          );
        }
      } else {
        debugPrint("ℹ️ No user logged in, navigating to Dashboard");
        if (context.mounted) {
          Get.offAll(
            () => const Dashboard(),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error checking login status: $e\n$stackTrace");
      if (context.mounted) {
        Get.snackbar(
          'Error',
          e is TimeoutException
              ? 'Network timeout. Using cached data.'
              : e is FirebaseException
                  ? 'Firebase error: ${e.message}'
                  : 'Unexpected error: Try again later.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 10,
          mainButton: TextButton(
            onPressed: () => checkLoginStatus(context),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        );
      }

      // Fallback navigation to Dashboard
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Get.offAll(
          () => const Dashboard(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  Future<String> _getUserName(User user, bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Try cached data first
      final cachedName = prefs.getString('user_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        debugPrint("ℹ️ Using cached user name: $cachedName");
        return cachedName;
      }

      if (!isOnline) {
        debugPrint("⚠️ Offline: Using fallback name");
        return user.displayName?.trim() ??
            user.email?.split('@')[0] ??
            'User-${user.uid.substring(0, 6)}';
      }

      // Fetch from Firestore with a timeout
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        throw TimeoutException('Firestore query timed out');
      });

      String userName = userDoc.exists
          ? userDoc['name']?.toString() ?? ''
          : user.displayName?.trim() ?? '';

      if (userName.isEmpty) {
        userName = user.email?.split('@')[0] ?? 'User-${user.uid.substring(0, 6)}';
      }

      // Cache the name
      await prefs.setString('user_name', userName);
      debugPrint("✅ Cached user name: $userName");
      return userName.isNotEmpty ? userName : 'Unknown';
    } catch (e) {
      debugPrint("⚠️ Error fetching user name: $e");
      String userName = user.displayName?.trim() ??
          user.email?.split('@')[0] ??
          'User-${user.uid.substring(0, 6)}';
      await prefs.setString('user_name', userName);
      return userName.isNotEmpty ? userName : 'Unknown';
    }
  }
}