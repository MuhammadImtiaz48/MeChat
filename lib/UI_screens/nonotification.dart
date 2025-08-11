import 'package:estate/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoNotificationScreen extends StatelessWidget {
  const NoNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 100.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/Frame.png", scale: 2.0,),
              SizedBox(height: 20.h,),
              Text("No Notifications Yet",style: TextStyle(fontSize: 20.sp,fontWeight: FontWeight.bold),),
              SizedBox(height: 10.h,),
              Text("No notification right now, notifications \nabout your activity will show up here.",style: TextStyle(fontSize: 16.sp,color: Colors.grey),),
              SizedBox(height: 40.h,),
              CustomElevatedButton(text: "Notifications Settings", color: Colors.black,
              onPressed: (){})
            ],
          ),
        ),
      ),
    );
  }
}
