
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:imtiaz/views/auth/login.dart';
import 'package:imtiaz/views/ui_screens/home.dart';

class SplashController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var isLoading = true.obs;
  var isOnline = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    _checkUserStatus();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isOnline.value = connectivityResult != ConnectivityResult.none;
    if (!isOnline.value) {
      errorMessage.value = 'No internet connection. Please check your network.';
      isLoading.value = false;
    }
  }

  Future<void> _checkUserStatus() async {
    try {
      if (!isOnline.value) return;

      // Wait for Firebase Auth to initialize
      await Future.delayed(const Duration(seconds: 2)); // Simulate delay for splash effect

      User? user = _auth.currentUser;

      if (user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String userName = userDoc['name']?.toString().trim() ??
              user.email?.split('@')[0] ??
              'User-${user.uid.substring(0, 6)}';
          // Navigate to HomeScreen for valid users
          Get.offAll(() => HomeScreen(userName: userName));
        } else {
          // User exists in Auth but not in Firestore, redirect to LoginScreen
          errorMessage.value = 'User data not found. Please log in again.';
          Get.offAll(() => const LoginScreen());
        }
      } else {
        // No user logged in, redirect to LoginScreen
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      errorMessage.value = 'Error checking user status: $e';
      isLoading.value = false;
      // Stay on SplashScreen to show error, user can retry manually
    }
  }

  void retry() {
    isLoading.value = true;
    errorMessage.value = '';
    _checkConnectivity();
    _checkUserStatus();
  }
}
