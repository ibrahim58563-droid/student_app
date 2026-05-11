import 'package:students_app/features/students/domain/entities/student.dart';

abstract interface class StudentsRepository {
  Future<List<Student>> getStudents();
}
