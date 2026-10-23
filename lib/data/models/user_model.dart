enum UserRole {
  student,
  driver,
  admin;

  static UserRole parse(String? value) => UserRole.values.firstWhere((r) => r.name == value, orElse: () => UserRole.student);

  String get label => switch (this) {
    UserRole.student => 'Student',
    UserRole.driver => 'Driver',
    UserRole.admin => 'Admin',
  };
}

class UserModel {
  const UserModel({required this.id, required this.name, required this.email, required this.role, this.phone, this.createdAt});

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final DateTime? createdAt;

  bool get isDriver => role == UserRole.driver;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as String,
    name: (map['name'] as String?) ?? '',
    email: (map['email'] as String?) ?? '',
    role: UserRole.parse(map['role'] as String?),
    phone: map['phone'] as String?,
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'phone': phone,
    'created_at': createdAt?.toIso8601String(),
  };

  UserModel copyWith({String? name, String? phone}) =>
      UserModel(id: id, name: name ?? this.name, email: email, role: role, phone: phone ?? this.phone, createdAt: createdAt);
}
