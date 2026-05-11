import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/students/data/data_sources/students_remote_data_source.dart';
import 'package:students_app/features/students/data/repositories/students_repository_impl.dart';
import 'package:students_app/features/students/domain/entities/student.dart';
import 'package:students_app/features/students/domain/use_cases/get_students_use_case.dart';

final studentsProvider = FutureProvider<List<Student>>((ref) {
  final remoteDataSource = const StudentsRemoteDataSource();
  final repository = StudentsRepositoryImpl(remoteDataSource);
  final useCase = GetStudentsUseCase(repository);
  return useCase();
});
