import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/signup_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 80.sp, color: const Color(0xFF075E54)),
                SizedBox(height: 16.h),
                Text('Create Account', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF075E54))),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF075E54)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF075E54)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
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
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF075E54)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Confirm your password';
                    if (value.trim() != controller.passwordController.text.trim()) return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                Obx(() => controller.loading.value
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF075E54)))
                    : ElevatedButton(
                        onPressed: controller.signup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50.h),
                          backgroundColor: const Color(0xFF075E54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          elevation: 2,
                        ),
                        child: Text('Create Account', style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text('OR', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  ],
                ),
                SizedBox(height: 16.h),
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.loading.value ? null : controller.signUpWithGoogle,
                      icon: Image.asset('assets/images/google.png', height: 24.h, width: 24.w),
                      label: Text('Continue with Google', style: TextStyle(fontSize: 16.sp, color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50.h),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        backgroundColor: Colors.white,
                      ),
                    )),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () => Get.toNamed('/login'),
                  child: Text('Already have an account? Login', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF075E54))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}