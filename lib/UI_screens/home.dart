import 'package:estate/UI_screens/massages.dart';
import 'package:estate/UI_screens/notification.dart';
import 'package:estate/controllers/bottom_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

// Dummy Screens for navigation

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Discover"));
  }
}

class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("My Home"));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Profile"));
  }
}

// Your actual Home screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());

  final List<Widget> screens = [
    HomeScreenContent(),
    MessagesScreen(),
    DiscoverScreen(),
    MyHomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: 
          screens[controller.selectedIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: controller.selectedIndex.value,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            onTap: controller.changeTab,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
              BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: "Discover"),
              BottomNavigationBarItem(icon: Icon(Icons.house), label: "My Home"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ));
  }
}

// Main content of the Home tab
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        children: [
           SizedBox(height: 40.h),
          Row(
            children: [
              Text("Location", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            ],
          ),
        
          Row(
            children: [
              Icon(Icons.location_on_outlined,size: 18.sp,color: Colors.blue,),
              Padding(
                padding: const EdgeInsets.only(right: 150),
                child: Text("Hanoi, Vietnam", style: TextStyle(fontSize: 14.sp, color: Colors.black,fontWeight: FontWeight.bold)),
              ),
              
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
                },
                child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.notifications_on_outlined))),
               

            ],
          ),
          SizedBox(height: 40.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1.2.w),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TextField(
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(fontSize: 14.sp),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 24.sp),
                suffixIcon: Icon(Icons.mic, size: 24.sp),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              children: [
                buildImageCard("assets/images/IMG (2).png"),
                buildImageCard("assets/images/img (3).png"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageCard(String imagePath) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400.h,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(Icons.favorite_border, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 10.h,
            left: 10.w,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Mighty Cinco Family",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold)),
                      Text("\$436",
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: Colors.grey, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text("Jakarta, Indonesia",
                              style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                        ],
                      ),
                      Text("per month",
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
