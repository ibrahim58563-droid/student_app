import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/students/data/data_sources/students_remote_data_source.dart';
import 'package:students_app/features/students/domain/entities/student.dart';

final studentsProvider = FutureProvider<List<Student>>((_) async {
  final remoteDataSource = StudentsRemoteDataSource();
  final models = await remoteDataSource.fetchStudents();
  return models.map((model) => model.toEntity()).toList();
});
