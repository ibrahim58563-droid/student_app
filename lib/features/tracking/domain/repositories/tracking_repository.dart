import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';

abstract interface class TrackingRepository {
  Future<DailyTracking> fetchTracking(String studentId, DateTime date);
  Future<void> updateIbadaatField(String trackingId, String field, bool value);
  Future<void> updateQuran(String trackingId, Map<String, dynamic> data);
  Future<void> toggleHabit(String habitId, bool value);
  Future<void> upsertStudySession(String trackingId, StudySession session);
}
