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
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Disabled due to API changes

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> signInWithGoogle() async {
    loading.value = true;
    try {
      // Google Sign-In is disabled for now due to API changes
      Get.snackbar('Error', 'Google Sign-In is temporarily unavailable', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;

      // Commented out the problematic code
      /*
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        loading.value = false;
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Save/Update user data in Firestore
        final userDoc = _firestore.collection('users').doc(user.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final name = user.displayName ?? googleUser.email.split('@')[0];
        await userDoc.set({
          'uid': user.uid,
          'name': name,
          'email': user.email ?? googleUser.email,
          'fcmToken': fcmToken ?? '',
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_uid', user.uid);
        await prefs.setString('user_email', user.email ?? googleUser.email);

        Get.off(() => HomeScreen(userName: name));
      }
      */
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Google sign-in failed', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Google sign-in failed: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
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
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      }
      Get.snackbar('Error', errorMessage, backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Login failed: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }
}