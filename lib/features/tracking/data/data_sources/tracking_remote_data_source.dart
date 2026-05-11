import 'package:students_app/features/tracking/data/models/daily_tracking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class TrackingRemoteDataSource {
  TrackingRemoteDataSource([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> saveDailyTracking(DailyTrackingModel model) async {
    await _client.from('daily_tracking').upsert({
      'student_id': model.studentId,
      'tracking_date': _formatDate(model.date),
      'prayer_score': model.prayerScore,
      'quran_memorization_pages': model.quranMemorizationPages,
      'quran_review_pages': model.quranReviewPages,
      'study_minutes': model.studyMinutes,
    }, onConflict: 'student_id,tracking_date');
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
