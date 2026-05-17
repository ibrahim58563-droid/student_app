import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';

final class DailyTrackingModel {
  const DailyTrackingModel({
    required this.studentId,
    required this.date,
    this.trackingId,
    this.ibadaat = const Ibadaat(),
    this.quran = const QuranData(),
    this.habits = const [],
    this.studySessions = const [],
  });

  final String studentId;
  final DateTime date;
  final String? trackingId;
  final Ibadaat ibadaat;
  final QuranData quran;
  final List<HabitItem> habits;
  final List<StudySession> studySessions;

  DailyTracking toEntity() {
    return DailyTracking(
      studentId: studentId,
      date: date,
      trackingId: trackingId,
      ibadaat: ibadaat,
      quran: quran,
      habits: habits,
      studySessions: studySessions,
    );
  }
}
