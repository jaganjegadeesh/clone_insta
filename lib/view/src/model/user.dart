class UserModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String dob;
  final String role;
  final String imageUrl;
  final String gender;
  final String password;

  UserModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.role,
    required this.imageUrl,
    required this.gender,
    required this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      password: json['password'] ?? '',
    );
  }
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone,  dob: $dob,  gender: $gender, password: $password, role: $role, imageUrl: $imageUrl)';
  }
}