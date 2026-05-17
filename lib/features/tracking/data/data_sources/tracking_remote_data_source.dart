import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class TrackingRemoteDataSource {
  TrackingRemoteDataSource([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> getOrCreateTrackingId(String studentId, DateTime date) async {
    final dateStr = _formatDate(date);

    final existing = await _client
        .from('daily_tracking')
        .select('id')
        .eq('student_id', studentId)
        .eq('tracking_date', dateStr)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final inserted = await _client
        .from('daily_tracking')
        .insert({'student_id': studentId, 'tracking_date': dateStr})
        .select('id')
        .single();

    final trackingId = inserted['id'] as String;

    await Future.wait([
      _seedIbadaat(trackingId),
      _seedQuran(trackingId),
      _seedDefaultHabits(trackingId),
    ]);

    return trackingId;
  }

  Future<DailyTracking> fetchTracking(String studentId, DateTime date) async {
    final trackingId = await getOrCreateTrackingId(studentId, date);

    final ibaadatData = await _client
        .from('ibadaat')
        .select()
        .eq('tracking_id', trackingId)
        .maybeSingle();
    final quranData = await _client
        .from('quran_tracking')
        .select()
        .eq('tracking_id', trackingId)
        .maybeSingle();
    final habitsData = await _client
        .from('habits')
        .select()
        .eq('tracking_id', trackingId);
    final studyData = await _client
        .from('study_sessions')
        .select()
        .eq('tracking_id', trackingId);

    return DailyTracking(
      studentId: studentId,
      date: date,
      trackingId: trackingId,
      ibadaat: ibaadatData == null
          ? const Ibadaat()
          : Ibadaat(
              fajr: ibaadatData['fajr'] as bool? ?? false,
              dhuhr: ibaadatData['dhuhr'] as bool? ?? false,
              asr: ibaadatData['asr'] as bool? ?? false,
              maghrib: ibaadatData['maghrib'] as bool? ?? false,
              isha: ibaadatData['isha'] as bool? ?? false,
              morningAdhkar: ibaadatData['morning_adhkar'] as bool? ?? false,
              eveningAdhkar: ibaadatData['evening_adhkar'] as bool? ?? false,
            ),
      quran: quranData == null
          ? const QuranData()
          : QuranData(
              currentSurah: quranData['current_surah'] as String? ?? '',
              hifzPages: (quranData['hifz_pages'] as num? ?? 0).toDouble(),
              revisionPages: (quranData['revision_pages'] as num? ?? 0)
                  .toDouble(),
              tilawahDone: quranData['tilawah_done'] as bool? ?? false,
            ),
      habits: habitsData
          .map(
            (habit) => HabitItem(
              id: habit['id'] as String?,
              name: habit['habit_name'] as String,
              isCompleted: habit['is_completed'] as bool? ?? false,
            ),
          )
          .toList(),
      studySessions: studyData
          .map(
            (session) => StudySession(
              id: session['id'] as String?,
              subject: session['subject'] as String,
              hoursSpent: (session['hours_spent'] as num? ?? 0).toDouble(),
              taskDescription: session['task_description'] as String? ?? '',
              gradeScore: (session['grade_score'] as num?)?.toDouble(),
            ),
          )
          .toList(),
    );
  }

  Future<void> updateIbadaatField(
    String trackingId,
    String field,
    bool value,
  ) async {
    await _client
        .from('ibadaat')
        .update({field: value})
        .eq('tracking_id', trackingId);
  }

  Future<void> updateQuran(String trackingId, Map<String, dynamic> data) async {
    await _client
        .from('quran_tracking')
        .update(data)
        .eq('tracking_id', trackingId);
  }

  Future<void> toggleHabit(String habitId, bool value) async {
    await _client
        .from('habits')
        .update({'is_completed': value})
        .eq('id', habitId);
  }

  Future<void> upsertStudySession(
    String trackingId,
    StudySession session,
  ) async {
    if (session.id != null) {
      await _client
          .from('study_sessions')
          .update({
            'hours_spent': session.hoursSpent,
            'task_description': session.taskDescription,
            'grade_score': session.gradeScore,
          })
          .eq('id', session.id!);
      return;
    }

    await _client.from('study_sessions').insert({
      'tracking_id': trackingId,
      'subject': session.subject,
      'hours_spent': session.hoursSpent,
      'task_description': session.taskDescription,
      'grade_score': session.gradeScore,
    });
  }

  Future<void> _seedIbadaat(String trackingId) async {
    await _client.from('ibadaat').insert({'tracking_id': trackingId});
  }

  Future<void> _seedQuran(String trackingId) async {
    await _client.from('quran_tracking').insert({'tracking_id': trackingId});
  }

  Future<void> _seedDefaultHabits(String trackingId) async {
    const defaults = ['رياضة', 'قراءة', 'نوم ٨ ساعات', 'شرب الماء'];
    await _client
        .from('habits')
        .insert(
          defaults
              .map((habit) => {'tracking_id': trackingId, 'habit_name': habit})
              .toList(),
        );
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
