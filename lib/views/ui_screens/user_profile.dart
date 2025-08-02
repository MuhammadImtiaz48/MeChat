import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imtiaz/models/userchat.dart';
import 'package:imtiaz/ui_screens/main.dart';
import 'package:imtiaz/widgets/buttens.dart';
import 'package:imtiaz/widgets/textfeilds.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key, required UserchatModel user});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  File? _pickedImage;
  String? imageUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _aboutController.text = data['about'] ?? '';
        imageUrl = data['image'];
      });
    }
  }

  void _showBottomBar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bc) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 160,
          child: Column(
            children: [
              const Text('Upload Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    onPressed: () async {
                      Navigator.pop(context);
                      final XFile? photo =
                          await picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        setState(() {
                          _pickedImage = File(photo.path);
                        });
                        // TODO: Upload to Firebase Storage and update Firestore
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text("Gallery"),
                    onPressed: () async {
                      Navigator.pop(context);
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          _pickedImage = File(image.path);
                        });
                        // TODO: Upload to Firebase Storage and update Firestore
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _updateProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text.trim(),
      'about': _aboutController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile Updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultImage = imageUrl ?? "https://via.placeholder.com/150";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontSize: 25)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : NetworkImage(defaultImage) as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 17, color: Colors.white),
                      onPressed: () => _showBottomBar(context),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Textfeilds(
                text: "Name",
                icon: const Icon(Icons.person, color: Colors.blue),
                hint: "Enter your name",
                controll: _nameController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Textfeilds(
                text: "About",
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                hint: "Hi, I'm using MeChat",
                controll: _aboutController,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Buttens(
                btname: "Update",
                textStyle: const TextStyle(color: Colors.white),
                bgcolor: const Color.fromARGB(255, 14, 16, 17),
                callBack: _updateProfile,
              ),
            ),
            const SizedBox(height: 30),
            Buttens(
              btname: "Logout",
              textStyle: const TextStyle(color: Colors.white),
              bgcolor: const Color.fromARGB(255, 243, 130, 96),
              callBack: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                  (route) => false,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
