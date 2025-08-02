class UserchatModel {
  final String uid;
  final String name;
  final String email;
  final String image;
  //final String lastActive;

  UserchatModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    //required this.lastActive,
  });

  factory UserchatModel.fromJson(Map<String, dynamic> json) {
    return UserchatModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'] ?? '',
      //lastActive: json['lastActive'],
    );
  }

  static fromMap(Map<String, dynamic> data) {}
}
