import 'package:students_app/features/students/domain/entities/student.dart';
import 'package:students_app/features/students/domain/repositories/students_repository.dart';

final class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository);

  final StudentsRepository _repository;

  Future<List<Student>> call() {
    return _repository.getStudents();
  }
}
