class UserModel {
  final String id;
  final String name;
  final String email;
  final String mode;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mode,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'].toString(),
        name: j['name'] as String,
        email: j['email'] as String,
        mode: j['mode'] as String? ?? 'student',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mode': mode,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
