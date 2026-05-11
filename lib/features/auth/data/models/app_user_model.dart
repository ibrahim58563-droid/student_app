import 'package:students_app/features/auth/domain/entities/app_user.dart';

final class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String,
      name: map['full_name'] as String? ?? 'مستخدم',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
    );
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role == 'admin' ? UserRole.admin : UserRole.student,
    );
  }
}
