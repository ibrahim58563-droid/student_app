/// Ibadaat (prayers) tracking data
final class IbadaatData {
  const IbadaatData({
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

  static const int totalCount = 7;
}

/// Quran tracking data
final class QuranData {
  const QuranData({
    this.currentSurah,
    this.pages = 0,
    this.reviewed = false,
    this.memorized = false,
  });

  final String? currentSurah;
  final int pages;
  final bool reviewed;
  final bool memorized;
}

/// Habit tracking data
final class HabitTrackingData {
  const HabitTrackingData({
    required this.habitId,
    required this.name,
    this.completed = false,
  });

  final String habitId;
  final String name;
  final bool completed;
}

/// Study session data
final class StudySessionData {
  const StudySessionData({
    required this.subject,
    this.hoursSpent = 0,
    this.dailyGoal = 2,
    this.id,
  });

  final String? id;
  final String subject;
  final double hoursSpent;
  final double dailyGoal;

  double get progress => (hoursSpent / dailyGoal).clamp(0.0, 1.0);
}

/// Complete tracking data for a student on a specific day
final class StudentTrackingData {
  const StudentTrackingData({
    required this.trackingId,
    required this.studentId,
    required this.trackingDate,
    this.ibadaat = const IbadaatData(),
    this.quran = const QuranData(),
    this.habits = const [],
    this.studySessions = const [],
  });

  final String trackingId;
  final String studentId;
  final DateTime trackingDate;
  final IbadaatData ibadaat;
  final QuranData quran;
  final List<HabitTrackingData> habits;
  final List<StudySessionData> studySessions;

  double calculateProgress() {
    final ibadaatScore = ibadaat.completedCount / IbadaatData.totalCount;
    final quranScore = (quran.reviewed || quran.memorized) ? 1.0 : 0.0;
    final habitsScore = habits.isEmpty
        ? 0.0
        : habits.where((habit) => habit.completed).length / habits.length;
    final studyScore = studySessions.isEmpty
        ? 0.0
        : studySessions.fold(0.0, (sum, session) => sum + session.progress) /
              studySessions.length;
    return (ibadaatScore + quranScore + habitsScore + studyScore) / 4;
  }
}

/// Student profile data
final class StudentProfileData {
  const StudentProfileData({
    required this.id,
    required this.fullName,
    this.email = '',
    this.avatarIndex = 0,
    this.grade,
    this.groupName,
    this.currentStreak = 0,
    this.notes,
  });

  final String id;
  final String fullName;
  final String email;
  final int avatarIndex;
  final String? grade;
  final String? groupName;
  final int currentStreak;
  final String? notes;

  factory StudentProfileData.fromJson(Map<String, dynamic> json) {
    return StudentProfileData(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Student',
      email: json['email'] as String? ?? '',
      avatarIndex: json['avatar_index'] as int? ?? 0,
      grade: json['grade'] as String?,
      groupName: json['group_name'] as String?,
      currentStreak: json['current_streak'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}
