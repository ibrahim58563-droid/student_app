import 'package:students_app/features/students/data/models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class StudentsRemoteDataSource {
  StudentsRemoteDataSource([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<StudentModel>> fetchStudents() async {
    final userId = _client.auth.currentUser?.id;
    final response = await _client
        .from('profiles')
        .select('id, full_name, grade, group_name, avatar_index')
        .eq('role', 'student')
        .eq('admin_id', userId!)
        .order('full_name');

    return (response as List)
        .map((data) => StudentModel.fromMap(data as Map<String, dynamic>))
        .toList();
  }
}
