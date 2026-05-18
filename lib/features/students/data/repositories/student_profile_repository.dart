import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/tracking/data/data_sources/tracking_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for student profile - delegates tracking to TrackingRemoteDataSource
final class StudentProfileRepository {
  StudentProfileRepository(this._supabaseClient)
    : _trackingSource = TrackingRemoteDataSource(_supabaseClient);

  final SupabaseClient _supabaseClient;
  final TrackingRemoteDataSource _trackingSource;

  /// Fetch student profile by ID
  Future<StudentProfileData> fetchStudentProfile(String studentId) async {
    final profile = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', studentId)
        .single();

    final streak = await _calculateCurrentStreak(studentId);
    final data = Map<String, dynamic>.from(profile);
    data['current_streak'] = streak;
    return StudentProfileData.fromJson(data);
  }

  /// Fetch today's tracking - delegates to TrackingRemoteDataSource (correct schema)
  Future<StudentTrackingData> fetchTodayTracking(String studentId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final tracking = await _trackingSource.fetchTracking(studentId, today);

    return StudentTrackingData(
      trackingId: tracking.trackingId ?? '',
      studentId: tracking.studentId,
      trackingDate: tracking.date,
      ibadaat: IbadaatData(
        fajr: tracking.ibadaat.fajr,
        dhuhr: tracking.ibadaat.dhuhr,
        asr: tracking.ibadaat.asr,
        maghrib: tracking.ibadaat.maghrib,
        isha: tracking.ibadaat.isha,
        morningAdhkar: tracking.ibadaat.morningAdhkar,
        eveningAdhkar: tracking.ibadaat.eveningAdhkar,
      ),
      quran: QuranData(
        currentSurah: tracking.quran.currentSurah,
        pages:
            tracking.quran.hifzPages.toInt() +
            tracking.quran.revisionPages.toInt(),
        reviewed: tracking.quran.revisionPages > 0,
        memorized: tracking.quran.hifzPages > 0,
      ),
      habits: tracking.habits
          .map(
            (habit) => HabitTrackingData(
              habitId: habit.id ?? '',
              name: habit.name,
              completed: habit.isCompleted,
            ),
          )
          .toList(),
      studySessions: tracking.studySessions
          .map(
            (session) => StudySessionData(
              id: session.id,
              subject: session.subject,
              hoursSpent: session.hoursSpent,
              dailyGoal: 2.0,
            ),
          )
          .toList(),
    );
  }

  /// Update ibadaat - delegates to TrackingRemoteDataSource
  Future<void> updateIbadaat(
    String trackingId,
    String field,
    bool value,
  ) async {
    await _trackingSource.updateIbadaatField(trackingId, field, value);
  }

  /// Update quran - delegates to TrackingRemoteDataSource
  Future<void> updateQuran(String trackingId, Map<String, dynamic> data) async {
    final mapped = <String, dynamic>{};
    if (data.containsKey('reviewed')) {
      mapped['revision_pages'] = (data['reviewed'] as bool) ? 1.0 : 0.0;
    }
    if (data.containsKey('memorized')) {
      mapped['hifz_pages'] = (data['memorized'] as bool) ? 1.0 : 0.0;
    }
    if (data.containsKey('current_surah')) {
      mapped['current_surah'] = data['current_surah'];
    }
    if (mapped.isNotEmpty) {
      await _trackingSource.updateQuran(trackingId, mapped);
    }
  }

  /// Toggle habit - delegates to TrackingRemoteDataSource
  Future<void> toggleHabit(String trackingId, String habitId) async {
    final habit = await _supabaseClient
        .from('habits')
        .select('is_completed')
        .eq('tracking_id', trackingId)
        .eq('id', habitId)
        .maybeSingle();

    if (habit != null) {
      final currentValue = habit['is_completed'] as bool? ?? false;
      await _trackingSource.toggleHabit(habitId, !currentValue);
    }
  }

  /// Update study session - delegates to TrackingRemoteDataSource
  Future<void> updateStudySession(
    String trackingId,
    String subject,
    double hoursSpent,
    double dailyGoal,
  ) async {
    final sessions = await _supabaseClient
        .from('study_sessions')
        .select('id')
        .eq('tracking_id', trackingId)
        .eq('subject', subject);

    if ((sessions as List).isNotEmpty) {
      await _supabaseClient
          .from('study_sessions')
          .update({'hours_spent': hoursSpent})
          .eq('id', sessions[0]['id']);
    } else {
      await _supabaseClient.from('study_sessions').insert({
        'tracking_id': trackingId,
        'subject': subject,
        'hours_spent': hoursSpent,
        'task_description': '',
      });
    }
  }

  Future<int> _calculateCurrentStreak(String studentId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30));

      final rows = await _supabaseClient
          .from('daily_tracking')
          .select('tracking_date')
          .eq('student_id', studentId)
          .gte(
            'tracking_date',
            thirtyDaysAgo.toIso8601String().split('T').first,
          )
          .order('tracking_date', ascending: false);

      final dates = (rows as List)
          .map((r) => DateTime.parse(r['tracking_date'] as String))
          .toSet();

      int streak = 0;
      var day = DateTime(now.year, now.month, now.day);

      for (int i = 0; i < 30; i++) {
        if (dates.contains(day)) {
          streak++;
          day = day.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (_) {
      return 0;
    }
  }
}
