import 'package:supabase_flutter/supabase_flutter.dart';

final class DashboardRemoteDataSource {
  DashboardRemoteDataSource([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, int>> fetchSummary() async {
    try {
      final studentsResponse = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'student');
      final totalStudents = (studentsResponse as List).length;

      final today = DateTime.now().toIso8601String().split('T').first;
      final trackingResponse = await _client
          .from('daily_tracking')
          .select('id')
          .eq('tracking_date', today);
      final todayTracking = (trackingResponse as List).length;

      return {
        'totalStudents': totalStudents,
        'todayAttendance': todayTracking,
        'completedTracking': todayTracking,
      };
    } catch (_) {
      return {'totalStudents': 0, 'todayAttendance': 0, 'completedTracking': 0};
    }
  }
}
