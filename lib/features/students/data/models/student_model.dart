import 'package:students_app/features/students/domain/entities/student.dart';

final class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    required this.grade,
  });

  final String id;
  final String fullName;
  final String grade;

  Student toEntity() {
    return Student(id: id, fullName: fullName, grade: grade);
  }
}
