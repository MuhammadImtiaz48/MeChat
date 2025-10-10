import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loading = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    loading.value = true;
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Save/Update user data in Firestore
        final userDoc = _firestore.collection('users').doc(user.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final name = user.displayName ?? emailController.text.split('@')[0];
        await userDoc.set({
          'uid': user.uid,
          'name': name,
          'email': user.email ?? emailController.text.trim(),
          'fcmToken': fcmToken ?? '',
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_uid', user.uid);
        await prefs.setString('user_email', user.email ?? emailController.text.trim());

        Get.off(() => HomeScreen(userName: name));
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Login failed', backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Login failed: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      loading.value = false;
    }
  }
}