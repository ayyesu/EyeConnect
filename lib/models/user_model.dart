class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'volunteer' or 'visually_impaired'
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.fcmToken,
  });

  // Factory constructor to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      fcmToken: json['fcmToken'],
    );
  }

  // Method to convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'fcmToken': fcmToken,
    };
  }
}
