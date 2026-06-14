enum UserRole { admin, staff, conductor }

class User {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final bool isActive;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role.toString().split('.').last,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['full_name'],
      email: map['email'],
      password: map['password'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      isActive: map['is_active'] == 1,
    );
  }
}
