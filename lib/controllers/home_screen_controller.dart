import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imtiaz/models/userchat.dart';

class HomeController extends GetxController {
  var userList = <UserchatModel>[].obs;
  var isSearching = false.obs;
  var searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      var users = snapshot.docs.map((doc) {
        var data = doc.data();
        return UserchatModel.fromMap(data);
      }).toList();

      userList.value = users;
    }, onError: (e) {
      print("🔥 Firestore error: $e");
    });
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      fetchUsers();
    } else {
      userList.value = userList
          .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    fetchUsers();
  }
}
