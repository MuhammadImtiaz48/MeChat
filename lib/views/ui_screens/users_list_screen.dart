import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/users_list_controller.dart';
import 'package:imtiaz/widgets/user_chat_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsersListController());

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        title: Text(
          'Select Contact',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => controller.toggleSearch(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(controller),
            Expanded(
              child: Obx(() {
                if (controller.loadingUsers.value) {
                  return _buildLoadingState();
                }

                if (controller.filteredUsers.isEmpty) {
                  return _buildEmptyState(controller);
                }

                return _buildUsersList(controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(UsersListController controller) {
    return Obx(() => controller.isSearching.value
        ? Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(Icons.search, size: 24.w, color: const Color(0xFF075E54)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF075E54), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 24.w, color: Colors.grey[600]),
                        onPressed: controller.clearSearch,
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(fontSize: 16.sp),
              onChanged: (value) => controller.filterUsers(value),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildUsersList(UsersListController controller) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      itemCount: controller.filteredUsers.length,
      itemBuilder: (context, index) {
        final user = controller.filteredUsers[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4.r,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: UserChatCard(
            user: user,
            onTap: () => controller.startChatWithUser(user),
            loggedInUserName: controller.loggedInUserName.value,
            currentUserId: controller.currentUserId,
            senderId: '',
            senderName: '',
            message: '',
            time: null,
            seen: null,
            showSeen: null,
            maxWidth: null,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            height: 70.h,
            decoration: BoxDecoration(
              color: const Color(0xFFECE5DD),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4.r,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  margin: EdgeInsets.all(8.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120.w,
                        height: 16.h,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 80.w,
                        height: 12.h,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(UsersListController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 60.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No users found',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: () => controller.loadUsers(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF075E54)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF075E54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}