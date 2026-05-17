final class Ibadaat {
  const Ibadaat({
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    this.morningAdhkar = false,
    this.eveningAdhkar = false,
  });

  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final bool morningAdhkar;
  final bool eveningAdhkar;

  int get completedCount => [
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
    morningAdhkar,
    eveningAdhkar,
  ].where((value) => value).length;
}

final class QuranData {
  const QuranData({
    this.currentSurah = '',
    this.hifzPages = 0,
    this.revisionPages = 0,
    this.tilawahDone = false,
  });

  final String currentSurah;
  final double hifzPages;
  final double revisionPages;
  final bool tilawahDone;
}

final class HabitItem {
  const HabitItem({required this.name, this.isCompleted = false, this.id});

  final String? id;
  final String name;
  final bool isCompleted;
}

final class StudySession {
  const StudySession({
    required this.subject,
    this.hoursSpent = 0,
    this.taskDescription = '',
    this.gradeScore,
    this.id,
  });

  final String? id;
  final String subject;
  final double hoursSpent;
  final String taskDescription;
  final double? gradeScore;
}

final class DailyTracking {
  const DailyTracking({
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

  double get progress {
    final ibaadatScore = ibadaat.completedCount / 7;
    final quranScore =
        (quran.hifzPages > 0 ? 0.5 : 0) + (quran.revisionPages > 0 ? 0.5 : 0);
    final habitsScore = habits.isEmpty
        ? 0.0
        : habits.where((habit) => habit.isCompleted).length / habits.length;
    final studyScore = studySessions.isEmpty
        ? 0.0
        : studySessions.any((session) => session.hoursSpent > 0)
        ? 1.0
        : 0.0;

    return (ibaadatScore + quranScore + habitsScore + studyScore) / 4;
  }
}
