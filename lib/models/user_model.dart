class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.fcmToken,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      fcmToken: data['fcmToken'],
    );
  }

  // Convert UserModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }
}