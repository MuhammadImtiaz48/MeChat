import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:imtiaz/models/userchat.dart'; // ✅ Add this line

class Apis {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static User get user => auth.currentUser!;
  static Future<bool>userExist() async{
    return (await firestore.collection('users').doc(auth.currentUser!.uid).get()).exists;

  }
   static Future<void>createUser() async{
    //final time = DateTime.now().microsecondsSinceEpoch.toString;
   
//     final chatUser = UserchatModel(images: user.photoURL.toString(),
//      name: user.displayName.toString(),
//       about: "Hi im using MeChat", 
//       createdAt: time.toString(),
//        isOnline: false.toString(),
//         lastActive: time.toString(), id: user.uid, pushToken: "",
//          email: user.email.toString());
//      return await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
// }
}
}