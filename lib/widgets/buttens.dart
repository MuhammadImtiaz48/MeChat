import 'package:flutter/material.dart';

class Buttens extends StatelessWidget{
  final String btname;
  final Icon? icon;
  final Color? bgcolor;
  final TextStyle? textStyle;
  final VoidCallback? callBack;
  const Buttens({super.key,  required this.btname,
  this.bgcolor,
  this.icon,
  this.textStyle,
  this.callBack,});
 @override
  Widget build(BuildContext context) {
   return ElevatedButton(onPressed: (){
    callBack!();
   },
   style: ElevatedButton.styleFrom(
    shadowColor: bgcolor,
    backgroundColor: bgcolor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    )
   ), child: icon!= null ?  Row(
    children: [
      const SizedBox(width: 100,),
      icon!,
      const SizedBox(width: 20,),
      Text(btname,style: textStyle)
    ],

   ):Text(btname,style: textStyle)
   );
  }

}