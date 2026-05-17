import 'package:students_app/features/dashboard/domain/models/student_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for class insights
final class ClassInsights {
  const ClassInsights({required this.averageProgress, required this.topStreak});

  final double averageProgress;
  final int topStreak;
}

/// Dashboard repository - fetches student data and class insights
final class DashboardRepository {
  const DashboardRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Fetch all students with today's progress.
  /// Returns a list of StudentSummary sorted by progress (descending).
  Future<List<StudentSummary>> fetchAllStudents({String? groupFilter}) async {
    try {
      // Get all student profiles
      var query = _supabaseClient
          .from('profiles')
          .select()
          .eq('role', 'student');

      if (groupFilter != null && groupFilter.isNotEmpty) {
        query = query.eq('group_name', groupFilter);
      }

      final profiles = await query;

      // Enrich with today's progress
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final summaries = <StudentSummary>[];

      for (final profile in profiles) {
        final studentId = profile['id'] as String;
        final todayProgress = await _calculateTodayProgress(studentId, today);
        final streak = await _calculateCurrentStreak(studentId);

        summaries.add(
          StudentSummary(
            id: studentId,
            fullName: profile['full_name'] as String? ?? 'Student',
            avatarIndex: profile['avatar_index'] as int? ?? 0,
            grade: profile['grade'] as String?,
            groupName: profile['group_name'] as String?,
            todayProgress: todayProgress['progress'] as double,
            currentStreak: streak,
            tasksCompleted: todayProgress['completed'] as int,
            totalTasks: todayProgress['total'] as int,
          ),
        );
      }

      // Sort by progress descending
      summaries.sort((a, b) => b.todayProgress.compareTo(a.todayProgress));
      return summaries;
    } catch (e) {
      return [];
    }
  }

  /// Fetch unique group names for filter chips
  Future<List<String>> fetchGroupNames() async {
    try {
      final result = await _supabaseClient
          .from('profiles')
          .select('group_name')
          .neq('group_name', 'null');

      return (result as List)
          .map((e) => (e as Map)['group_name'] as String?)
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch class insights (average progress + top streak)
  Future<ClassInsights> fetchClassInsights() async {
    try {
      final students = await fetchAllStudents();

      if (students.isEmpty) {
        return const ClassInsights(averageProgress: 0, topStreak: 0);
      }

      final avgProgress =
          students.fold(0.0, (sum, s) => sum + s.todayProgress) /
          students.length;
      final topStreak = students.fold(
        0,
        (max, s) => s.currentStreak > max ? s.currentStreak : max,
      );

      return ClassInsights(averageProgress: avgProgress, topStreak: topStreak);
    } catch (e) {
      return const ClassInsights(averageProgress: 0, topStreak: 0);
    }
  }

  /// Fetch the last 7 days of progress for a student.
  Future<Map<DateTime, double>> fetchWeeklyProgress(String studentId) async {
    try {
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);

      final weeklyProgress = <DateTime, double>{};
      for (var offset = 6; offset >= 0; offset--) {
        final date = endDate.subtract(Duration(days: offset));
        final progress = await _calculateTodayProgress(studentId, date);
        weeklyProgress[date] = progress['progress'] as double;
      }

      return weeklyProgress;
    } catch (e) {
      return <DateTime, double>{};
    }
  }

  /// Calculate today's progress for a student
  /// Formula: (ibadaat/7 + quran + habits/count + study) / 4
  Future<Map<String, dynamic>> _calculateTodayProgress(
    String studentId,
    DateTime date,
  ) async {
    try {
      // Get today's tracking record
      final trackingList = await _supabaseClient
          .from('daily_tracking')
          .select()
          .eq('student_id', studentId)
          .eq('tracking_date', date.toString().split(' ')[0]);

      if (trackingList.isEmpty) {
        return {'progress': 0.0, 'completed': 0, 'total': 7};
      }

      final trackingId = trackingList[0]['id'] as String;

      // Calculate ibadaat score (0-1)
      var ibadaatScore = 0.0;
      try {
        final ibadaat = await _supabaseClient
            .from('ibadaat')
            .select()
            .eq('tracking_id', trackingId)
            .limit(1);

        if (ibadaat.isNotEmpty) {
          final record = ibadaat[0];
          final count = [
            record['fajr'],
            record['dhuhr'],
            record['asr'],
            record['maghrib'],
            record['isha'],
            record['morning_adhkar'],
            record['evening_adhkar'],
          ].whereType<bool>().where((v) => v).length;

          ibadaatScore = count / 7.0;
        }
      } catch (_) {}

      // Calculate quran score (0 or 1)
      var quranScore = 0.0;
      try {
        final quran = await _supabaseClient
            .from('quran_tracking')
            .select()
            .eq('tracking_id', trackingId)
            .limit(1);

        if (quran.isNotEmpty && quran[0]['tilawah_done'] == true) {
          quranScore = 1.0;
        }
      } catch (_) {}

      // Calculate habits score (0-1)
      var habitsScore = 0.0;
      var habitCount = 0;
      try {
        final habits = await _supabaseClient
            .from('habits')
            .select()
            .eq('tracking_id', trackingId);

        if (habits.isNotEmpty) {
          habitCount = habits.length;
          final completed = habits
              .whereType<Map>()
              .where((h) => h['is_completed'] == true)
              .length;
          habitsScore = completed / habitCount;
        }
      } catch (_) {}

      // Calculate study score (0 or 1)
      var studyScore = 0.0;
      try {
        final study = await _supabaseClient
            .from('study_sessions')
            .select()
            .eq('tracking_id', trackingId);

        if (study.isNotEmpty) {
          final hasSession = study.whereType<Map>().any((s) {
            final hours = s['hours_spent'] as num?;
            return hours != null && hours > 0;
          });
          studyScore = hasSession ? 1.0 : 0.0;
        }
      } catch (_) {}

      // Average the 4 scores
      final totalScore =
          (ibadaatScore + quranScore + habitsScore + studyScore) / 4.0;

      // Count completed tasks
      final ibadaatCount = (ibadaatScore * 7).round();
      final quranDone = quranScore > 0 ? 1 : 0;
      final habitsDone = (habitsScore * (habitCount > 0 ? habitCount : 1))
          .round();
      final studyDone = studyScore > 0 ? 1 : 0;

      final tasksCompleted = ibadaatCount + quranDone + habitsDone + studyDone;
      const totalTasks = 12; // Rough average

      return {
        'progress': totalScore.clamp(0.0, 1.0),
        'completed': tasksCompleted,
        'total': totalTasks,
      };
    } catch (e) {
      return {'progress': 0.0, 'completed': 0, 'total': 7};
    }
  }

  /// Calculate current streak (simplified: count consecutive days at 100%)
  Future<int> _calculateCurrentStreak(String studentId) async {
    try {
      int streak = 0;
      final now = DateTime.now();

      for (int i = 0; i < 365; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));

        final progress = await _calculateTodayProgress(studentId, date);
        final completed = progress['progress'] as double;

        if (completed >= 0.95) {
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
