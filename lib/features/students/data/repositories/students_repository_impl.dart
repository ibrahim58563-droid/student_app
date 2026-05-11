import 'package:students_app/features/students/data/data_sources/students_remote_data_source.dart';
import 'package:students_app/features/students/domain/entities/student.dart';
import 'package:students_app/features/students/domain/repositories/students_repository.dart';

final class StudentsRepositoryImpl implements StudentsRepository {
  const StudentsRepositoryImpl(this._remoteDataSource);

  final StudentsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Student>> getStudents() async {
    final models = await _remoteDataSource.fetchStudents();
    return models.map((model) => model.toEntity()).toList();
  }
}
