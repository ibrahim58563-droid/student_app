import 'package:students_app/features/students/data/models/student_model.dart';

final class StudentsRemoteDataSource {
  const StudentsRemoteDataSource();

  Future<List<StudentModel>> fetchStudents() async {
    return const [
      StudentModel(id: '1', fullName: 'محمد أحمد', grade: 'Grade 8'),
      StudentModel(id: '2', fullName: 'عبدالله خالد', grade: 'Grade 9'),
      StudentModel(id: '3', fullName: 'Yousef Ali', grade: 'Grade 10'),
    ];
  }
}
