import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imtiaz/firebase_Services/cloudinary_service.dart';
import 'package:imtiaz/controllers/app_controller.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path/path.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required UserchatModel user,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final picker = ImagePicker();
  final cloudinaryService = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isUploading = false;
  String? imageUrl;

  /// ✅ Upload profile image (only if logged-in user)
  Future<void> _uploadProfileImage() async {
    try {
      // Check if the logged-in user is viewing their own profile
      if (_auth.currentUser?.uid != widget.userId) {
        Get.snackbar(
          "Access Denied",
          "You can only update your own profile picture.",
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }

      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => isUploading = true);

      final filePath = pickedFile.path;

      // ✅ Upload to Cloudinary
      final cloudinaryUrl = await cloudinaryService.uploadImage(filePath);

      if (cloudinaryUrl == null) {
        throw Exception("Cloudinary upload failed");
      }

      // ✅ Update Firestore user document
      await _firestore.collection('users').doc(widget.userId).update({
        'profilePic': cloudinaryUrl,
      });

      setState(() {
        imageUrl = cloudinaryUrl;
        isUploading = false;
      });

      Get.snackbar(
        "✅ Success",
        "Profile picture updated successfully!",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() => isUploading = false);
      Get.snackbar(
        "❌ Error",
        "Failed to upload image: $e",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final loggedInUserId = _auth.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.only(left: 8.w, top: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF075E54)),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF075E54).withOpacity(0.2),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(widget.userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return _buildErrorState("User data not found", controller);
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final profilePic = imageUrl ?? userData['profilePic'] ?? '';
              final email = userData['email'] ?? 'No email';
              final lastActive = userData['lastActive'] as Timestamp?;

              final isOwnProfile = loggedInUserId == widget.userId;

              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: isOwnProfile ? _uploadProfileImage : null,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 90.r,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              child: profilePic.isEmpty
                                  ? const Icon(Icons.person, size: 90, color: Color(0xFF075E54))
                                  : null,
                            ),
                            if (isUploading)
                              Container(
                                width: 180,
                                height: 180,
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            if (isOwnProfile)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF075E54),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF075E54),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        email,
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        lastActive != null
                            ? 'Last seen: ${lastActive.toDate().toString().substring(0, 16)}'
                            : 'Last seen: Unknown',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 60.h),

                      /// ✅ Only show chat button for *other* users
                      if (!isOwnProfile)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Get.toNamed('/chat', arguments: {
                                'user': UserchatModel(
                                  uid: widget.userId,
                                  name: widget.userName,
                                  email: email,
                                  image: profilePic,
                                  fcmToken: userData['fcmToken'] ?? '',
                                  profilePic: profilePic,
                                  lastActive: lastActive?.toDate(),
                                ),
                                'loggedInUserName': controller.cachedUserData['name'] ?? 'Guest',
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF075E54),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: Text(
                                "Start Chat",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() => Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 90.r, backgroundColor: Colors.grey[300]),
              SizedBox(height: 24.h),
              Container(width: 180.w, height: 24.h, color: Colors.grey[300]),
            ],
          ),
        ),
      );

  Widget _buildErrorState(String msg, AppController controller) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60.sp),
            SizedBox(height: 12.h),
            Text(msg, style: TextStyle(fontSize: 16.sp, color: Colors.red)),
            ElevatedButton(
              onPressed: () => Get.offNamed('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
              ),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );
}
