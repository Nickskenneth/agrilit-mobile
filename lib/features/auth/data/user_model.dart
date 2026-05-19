class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? region;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.region,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        region: json['region'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  bool get isAdmin => role == 'admin';
  bool get isPakar => role == 'pakar';
  bool get isPetani => role == 'petani';
  bool get isExpert => role == 'admin' || role == 'pakar';
}
