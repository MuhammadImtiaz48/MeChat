import 'package:estate/UI_screens/home.dart';
import 'package:estate/widgets/buttons.dart';
import 'package:estate/widgets/textfeilds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
  TextSpan(
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24.sp,
    ),
    children: [
      TextSpan(text: "Create a "),
      TextSpan(
        text: "Realix",
        style: TextStyle(color: Colors.blue),
      ),
      TextSpan(text: " account"),
    ],
  ),
),

              SizedBox(height: 4.h),
              Text(
                "Create an account to continue",
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
              SizedBox(height: 40.h),
              CustomTextField(hintText: "Full Name"),
              SizedBox(height: 20.h),
              CustomTextField(hintText: "Phone number"),
              SizedBox(height: 20.h),
              CustomTextField(
                hintText: "Password",
                obscureText: true,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.remove_red_eye_outlined),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: 312.w,
                child: CustomElevatedButton(
                  text: "Sign Up",
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                  color: Colors.black,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                ),
              ),
              SizedBox(height: 30.h),
              Center(
                child: Text(
                  "Forgot password?",
                  style: TextStyle(color: Colors.grey, fontSize: 18.sp),
                ),
              ),
              SizedBox(height: 40.h),
              Center(
                child: Text(
                  "Or continue with social account",
                  style: TextStyle(color: Colors.grey, fontSize: 18.sp),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: socialButton("assets/images/google.png", "Google"),
              ),
              SizedBox(height: 10.h),
              Center(
                child: socialButton("assets/images/Facebook (2).png", "Facebook"),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "You already have an account?",
                    style: TextStyle(color: Colors.grey, fontSize: 18.sp),
                  ),
                  SizedBox(width: 6.w),
                  InkWell(
                    onTap: () {
                      // Handle sign up
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget socialButton(String imagePath, String text) {
    return Container(
      width: 300.w,
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 24.h, width: 24.w),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
