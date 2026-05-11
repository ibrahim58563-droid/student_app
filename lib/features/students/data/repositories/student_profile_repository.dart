import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for student profile and tracking data
final class StudentProfileRepository {
  const StudentProfileRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Fetch student profile by ID
  Future<StudentProfileData> fetchStudentProfile(String studentId) async {
    try {
      final profile = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', studentId)
          .single();

      // Calculate current streak
      final streak = await _calculateCurrentStreak(studentId);

      final data = profile.cast<String, dynamic>();
      data['current_streak'] = streak;

      return StudentProfileData.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch today's tracking data for a student
  Future<StudentTrackingData> fetchTodayTracking(String studentId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateStr = today.toString().split(' ')[0]; // YYYY-MM-DD

      // Try to fetch existing tracking record
      final existing = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('student_id', studentId)
          .eq('tracking_date', dateStr);

      if (existing.isNotEmpty) {
        return StudentTrackingData.fromJson(
          (existing[0] as Map).cast<String, dynamic>(),
        );
      }

      // Create new tracking record if doesn't exist
      final newTracking = await _supabaseClient
          .from('daily_tracking')
          .insert({
            'student_id': studentId,
            'tracking_date': dateStr,
            'ibadaat': {},
            'quran': {'reviewed': false, 'memorized': false},
            'habits': [],
            'study_sessions': [],
          })
          .select()
          .single();

      return StudentTrackingData.fromJson(
        (newTracking as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update ibadaat (prayers) status
  Future<void> updateIbadaat(
    String trackingId,
    String field,
    bool value,
  ) async {
    try {
      // Fetch current data
      final tracking = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('id', trackingId)
          .single();

      final ibadaat = tracking['ibadaat'] as Map<String, dynamic>? ?? {};
      ibadaat[field] = value;

      // Update
      await _supabaseClient
          .from('daily_tracking')
          .update({'ibadaat': ibadaat})
          .eq('id', trackingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update quran progress
  Future<void> updateQuran(String trackingId, Map<String, dynamic> data) async {
    try {
      // Fetch and merge
      final tracking = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('id', trackingId)
          .single();

      final quran = tracking['quran'] as Map<String, dynamic>? ?? {};
      quran.addAll(data);

      await _supabaseClient
          .from('daily_tracking')
          .update({'quran': quran})
          .eq('id', trackingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle habit completion
  Future<void> toggleHabit(String trackingId, String habitId) async {
    try {
      final tracking = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('id', trackingId)
          .single();

      final habits = (tracking['habits'] as List<dynamic>? ?? [])
          .map((h) => Map<String, dynamic>.from(h as Map))
          .toList();

      final habitIndex = habits.indexWhere((h) => h['id'] == habitId);
      if (habitIndex >= 0) {
        habits[habitIndex]['completed'] =
            !(habits[habitIndex]['completed'] as bool? ?? false);
      }

      await _supabaseClient
          .from('daily_tracking')
          .update({'habits': habits})
          .eq('id', trackingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update study session
  Future<void> updateStudySession(
    String trackingId,
    String subject,
    double hoursSpent,
    double dailyGoal,
  ) async {
    try {
      final tracking = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('id', trackingId)
          .single();

      final studySessions = (tracking['study_sessions'] as List<dynamic>? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      final sessionIndex = studySessions.indexWhere(
        (s) => s['subject'] == subject,
      );
      if (sessionIndex >= 0) {
        studySessions[sessionIndex]['hours_spent'] = hoursSpent;
        studySessions[sessionIndex]['daily_goal'] = dailyGoal;
      } else {
        studySessions.add({
          'subject': subject,
          'hours_spent': hoursSpent,
          'daily_goal': dailyGoal,
        });
      }

      await _supabaseClient
          .from('daily_tracking')
          .update({'study_sessions': studySessions})
          .eq('id', trackingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate current streak (consecutive days of 95%+ progress)
  Future<int> _calculateCurrentStreak(String studentId) async {
    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateStr = checkDate.toString().split(' ')[0];

        final tracking = await _supabaseClient
            .from('daily_tracking')
            .select()
            .eq('student_id', studentId)
            .eq('tracking_date', dateStr);

        if (tracking.isEmpty) {
          break;
        }

        // Calculate progress for this day
        final data = StudentTrackingData.fromJson(
          (tracking[0] as Map).cast<String, dynamic>(),
        );
        final progress = data.calculateProgress();

        if (progress >= 0.95) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }
}
