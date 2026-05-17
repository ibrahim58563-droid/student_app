import 'package:students_app/features/students/domain/entities/student.dart';

final class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    required this.grade,
    this.groupName,
    this.avatarIndex = 0,
  });

  final String id;
  final String fullName;
  final String grade;
  final String? groupName;
  final int avatarIndex;

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'طالب',
      grade: map['grade'] as String? ?? '',
      groupName: map['group_name'] as String?,
      avatarIndex: map['avatar_index'] as int? ?? 0,
    );
  }

  Student toEntity() {
    return Student(
      id: id,
      fullName: fullName,
      grade: grade,
      groupName: groupName,
      avatarIndex: avatarIndex,
    );
  }
}
