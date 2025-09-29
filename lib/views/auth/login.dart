import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/login_controller.dart';
import 'package:imtiaz/main.dart';
import 'package:imtiaz/views/ui_screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF075E54)),
              onPressed: () => Get.off(() => const Dashboard()),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'MeChat Login',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: const Color(0xFF075E54)),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.message, size: 80.sp, color: const Color(0xFF075E54)),
                    SizedBox(height: 16.h),
                    Text('Login to MeChat', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF075E54))),
                    SizedBox(height: 32.h),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF075E54)),
                        labelStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: controller.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF075E54)),
                        labelStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),
                    Obx(() => ElevatedButton(
                          onPressed: controller.loading.value ? null : controller.login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50.h),
                            backgroundColor: const Color(0xFF075E54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            elevation: 2,
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        )),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: () => Get.toNamed('/signup'),
                      child: Text('Don\'t have an account? Sign Up', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF075E54))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(() => controller.loading.value
            ? Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF075E54)),
                    strokeWidth: 4.w,
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}