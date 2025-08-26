import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:imtiaz/utils/lnvlidemail.dart';
import 'package:imtiaz/widgets/buttens.dart';
import 'package:imtiaz/widgets/massage.dart';
import 'package:imtiaz/widgets/textfeilds.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Create your account",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),
                Text(
                  "Connect instantly with friends and family,\nor explore new connections.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Name
                Textfeilds(
                  text: "Enter your name",
                  icon: Icon(Icons.person),
                  controll: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your name";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Email
                Textfeilds(
                  text: "Enter your email",
                  icon: Icon(Icons.email),
                  controll: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your email";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Password
                Textfeilds(
                  text: "Enter password",
                  icon: Icon(Icons.lock),
                  tohide: true,
                  controll: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Confirm Password
                Textfeilds(
                  text: "Confirm password",
                  icon: Icon(Icons.lock_outline),
                  tohide: true,
                  controll: confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Confirm your password";
                    }
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: 300,
                  child: Buttens(
                    btname: "Create an account",
                    textStyle: TextStyle(fontSize: 18, color: Colors.white),
                    bgcolor: Colors.black,
                    callBack: () {
                      if (_formKey.currentState!.validate()) {
                        auth.createUserWithEmailAndPassword(
                          email: emailController.text.toString(), 
                          password: passwordController.text.toString()).then((value){
                            Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Massage()),
                        );

                          }).onError((Error,StackTrace){
                         Utils().toastMessage(Error.toString());
                          });
                        
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
