final class DailyTracking {
  const DailyTracking({
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
}
