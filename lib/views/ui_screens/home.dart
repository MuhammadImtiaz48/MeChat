import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/chat_controller.dart';
import 'package:imtiaz/controllers/home_screen_controller.dart';
import 'package:imtiaz/views/ui_screens/user_profile.dart';
import 'package:imtiaz/widgets/user_chat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final HomeController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    controller.searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: Column(
          children: [
            // App Bar
            Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Obx(() {
                  // Fix for the ternary operator issue
                  Widget centerWidget;
                  
                  if (controller.isSearching.value) {
                    centerWidget = TextField(
                      controller: controller.searchController,
                      autofocus: true,
                      onChanged: (value) => controller.filterUsers(value.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search users by name',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    );
                  } else {
                    centerWidget = FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        "Me Chat",
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    );
                  }
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Icon(Icons.home, size: 30, color: Colors.white),
                      ),
                      Expanded(
                        child: Center(
                          child: centerWidget,
                        ),
                      ),
                      Row(
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: IconButton(
                              icon: Icon(
                                controller.isSearching.value ? Icons.close : Icons.search,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (controller.isSearching.value) {
                                  controller.clearSearch();
                                } else {
                                  controller.isSearching.value = true;
                                }
                              },
                            ),
                          ),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () {
                                if (controller.userList.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfile(user: controller.userList.first),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
            
            // Body
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Obx(() {
                  return controller.userList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No users found",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Start adding friends to chat with",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: controller.userList.length,
                          itemBuilder: (context, index) {
                            final user = controller.userList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(0.1 * index, 1.0, curve: Curves.easeIn),
                                  ),
                                ),
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserProfile(user: user),
                                        ),
                                      );
                                    },
                                    child: UserChatCard(user: user, controller: Get.put(UserChatController(user: user))),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            // Add action for floating button
          },
          backgroundColor: const Color(0xFF2575FC),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}