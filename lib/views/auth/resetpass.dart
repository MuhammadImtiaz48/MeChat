import 'package:flutter/material.dart';
import 'package:imtiaz/views/auth/login.dart';
import 'package:imtiaz/widgets/buttens.dart';
import 'package:imtiaz/widgets/textfeilds.dart';

class Resetpass extends StatefulWidget {
  const Resetpass({super.key});

  @override
  State<Resetpass> createState() => _ResetpassState();
}

class _ResetpassState extends State<Resetpass> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    oldPassController.dispose();
    newPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, left: 30, right: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reset Password",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 50),

              // Email
              Textfeilds(
                text: "Email",
                hint: "Enter your email",
                icon: const Icon(Icons.email),
                tohide: false,
                controll: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Old Password
              Textfeilds(
                text: "Old Password",
                hint: "Enter your old password",
                icon: const Icon(Icons.lock_outline),
                tohide: true,
                controll: oldPassController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter old password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // New Password
              Textfeilds(
                text: "New Password",
                hint: "Enter your new password",
                icon: const Icon(Icons.lock),
                tohide: true,
                controll: newPassController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter new password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Reset Button
              Center(
                child: SizedBox(
                  width: 300,
                  child: Buttens(
                    btname: "Reset",
                    bgcolor: Colors.black,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                    callBack: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Reset password logic
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
