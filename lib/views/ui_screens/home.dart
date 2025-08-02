import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/controllers/chat_controller.dart';
import 'package:imtiaz/controllers/home_screen_controller.dart';
import 'package:imtiaz/ui_screens/user_profile.dart';
import 'package:imtiaz/widgets/user_chat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
  }

  @override
  void dispose() {
    controller.searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        elevation: 0,
        title: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.home, size: 30, color: Colors.black),
                Expanded(
                  child: Center(
                    child: controller.isSearching.value
                        ? TextField(
                            controller: controller.searchController,
                            autofocus: true,
                            onChanged: (value) => controller.filterUsers(value.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search users by name',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                            style: const TextStyle(fontSize: 18, color: Colors.black),
                          )
                        : const Text(
                            "Me Chat",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        controller.isSearching.value ? Icons.close : Icons.search,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        if (controller.isSearching.value) {
                          controller.clearSearch();
                        } else {
                          controller.isSearching.value = true;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
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
                  ],
                ),
              ],
            )),
      ),
      body: Obx(() {
        return controller.userList.isEmpty
            ? const Center(child: Text("No users found."))
            : ListView.builder(
                itemCount: controller.userList.length,
                itemBuilder: (context, index) {
                  final user = controller.userList[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfile(user: user),
                        ),
                      );
                    },
                    child: UserChatCard(user: user, controller: Get.put(UserChatController(user: user))),
                  );
                },
              );
      }),
    );
  }
}
