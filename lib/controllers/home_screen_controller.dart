import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/userchat.dart';

class HomeController extends GetxController {
  var userList = <UserchatModel>[].obs;
  var allUsers = <UserchatModel>[].obs;
  var isSearching = false.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAllUsers();
  }

  Future<void> loadAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs.map((doc) => UserchatModel.fromJson(doc.data())).toList();
    allUsers.assignAll(users);
    userList.assignAll(users);
  }

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    final results = allUsers.where((user) => user.name.toLowerCase().contains(lowerQuery)).toList();
    userList.assignAll(results);
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    userList.assignAll(allUsers);
  }
}
