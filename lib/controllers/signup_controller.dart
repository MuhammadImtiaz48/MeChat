import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final loading = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Disabled due to API changes

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> signUpWithGoogle() async {
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
        final userDoc = _firestore.collection('users').doc(user.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final name = user.displayName ?? googleUser.email.split('@')[0];
        await userDoc.set({
          'uid': user.uid,
          'name': name,
          'email': user.email ?? googleUser.email,
          'fcmToken': fcmToken ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_uid', user.uid);
        await prefs.setString('user_email', user.email ?? googleUser.email);

        Get.off(() => HomeScreen(userName: name));
      }
      */
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Google sign-up failed', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Google sign-up failed: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }

  Future<void> signup() async {
    if (!formKey.currentState!.validate()) return;
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    loading.value = true;
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final name = nameController.text.trim();
        await userDoc.set({
          'uid': user.uid,
          'name': name,
          'email': user.email ?? emailController.text.trim(),
          'fcmToken': fcmToken ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_uid', user.uid);
        await prefs.setString('user_email', user.email ?? emailController.text.trim());

        Get.off(() => HomeScreen(userName: name));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password should be at least 6 characters';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }
      Get.snackbar('Error', errorMessage, backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Signup failed: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }
}