import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';

final class DailyTrackingModel {
  const DailyTrackingModel({
    required this.studentId,
    required this.date,
    required this.prayerScore,
    required this.quranMemorizationPages,
    required this.quranReviewPages,
    required this.studyMinutes,
  });

  final String studentId;
  final DateTime date;
  final int prayerScore;
  final int quranMemorizationPages;
  final int quranReviewPages;
  final int studyMinutes;

  DailyTracking toEntity() {
    return DailyTracking(
      studentId: studentId,
      date: date,
      prayerScore: prayerScore,
      quranMemorizationPages: quranMemorizationPages,
      quranReviewPages: quranReviewPages,
      studyMinutes: studyMinutes,
    );
  }
}
