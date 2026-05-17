/// Calculates daily progress score (0.0 to 1.0)
double calculateDailyProgress(Map<String, dynamic> data) {
  final ibadaatDone = (data['ibadaat_done'] as int? ?? 0);
  final quranHifz = (data['quran_hifz'] as double? ?? 0.0);
  final quranRevision = (data['quran_revision'] as double? ?? 0.0);
  final habitsDone = (data['habits_done'] as int? ?? 0);
  final habitsTotal = (data['habits_total'] as int? ?? 1);
  final studyHours = (data['study_hours'] as double? ?? 0.0);
  final studyGoal = (data['study_goal'] as double? ?? 2.0);

  final ibadaatScore = ibadaatDone / 7;
  final quranScore =
      (quranHifz > 0 ? 0.5 : 0.0) + (quranRevision > 0 ? 0.5 : 0.0);
  final habitsScore = habitsTotal > 0 ? habitsDone / habitsTotal : 0.0;
  final studyScore = studyGoal > 0
      ? (studyHours / studyGoal).clamp(0.0, 1.0)
      : 0.0;

  return (ibadaatScore + quranScore + habitsScore + studyScore) / 4;
}

String getProgressLabel(double progress) {
  if (progress >= 0.8) return 'ممتاز 🌟';
  if (progress >= 0.6) return 'جيد جداً 👍';
  if (progress >= 0.4) return 'جيد';
  return 'يحتاج متابعة';
}
