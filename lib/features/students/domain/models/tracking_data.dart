/// Ibadaat (prayers) tracking data
final class IbadaatData {
  const IbadaatData({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.morningAdhkar,
    required this.eveningAdhkar,
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
  ].where((v) => v).length;

  static const int totalCount = 7;

  factory IbadaatData.fromJson(Map<String, dynamic> json) {
    return IbadaatData(
      fajr: json['fajr'] as bool? ?? false,
      dhuhr: json['dhuhr'] as bool? ?? false,
      asr: json['asr'] as bool? ?? false,
      maghrib: json['maghrib'] as bool? ?? false,
      isha: json['isha'] as bool? ?? false,
      morningAdhkar: json['morning_adhkar'] as bool? ?? false,
      eveningAdhkar: json['evening_adhkar'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'fajr': fajr,
    'dhuhr': dhuhr,
    'asr': asr,
    'maghrib': maghrib,
    'isha': isha,
    'morning_adhkar': morningAdhkar,
    'evening_adhkar': eveningAdhkar,
  };
}

/// Quran tracking data
final class QuranData {
  const QuranData({
    required this.currentSurah,
    required this.pages,
    required this.reviewed,
    required this.memorized,
  });

  final String? currentSurah;
  final int pages;
  final bool reviewed;
  final bool memorized;

  factory QuranData.fromJson(Map<String, dynamic> json) {
    return QuranData(
      currentSurah: json['current_surah'] as String?,
      pages: json['pages'] as int? ?? 0,
      reviewed: json['reviewed'] as bool? ?? false,
      memorized: json['memorized'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'current_surah': currentSurah,
    'pages': pages,
    'reviewed': reviewed,
    'memorized': memorized,
  };
}

/// Habit tracking data
final class HabitTrackingData {
  const HabitTrackingData({
    required this.habitId,
    required this.name,
    required this.completed,
  });

  final String habitId;
  final String name;
  final bool completed;

  factory HabitTrackingData.fromJson(Map<String, dynamic> json) {
    return HabitTrackingData(
      habitId: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Study session data
final class StudySessionData {
  const StudySessionData({
    required this.subject,
    required this.hoursSpent,
    required this.dailyGoal,
  });

  final String subject;
  final double hoursSpent;
  final double dailyGoal;

  double get progress => (hoursSpent / dailyGoal).clamp(0, 1);

  factory StudySessionData.fromJson(Map<String, dynamic> json) {
    return StudySessionData(
      subject: json['subject'] as String? ?? '',
      hoursSpent: (json['hours_spent'] as num? ?? 0).toDouble(),
      dailyGoal: (json['daily_goal'] as num? ?? 2).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'hours_spent': hoursSpent,
    'daily_goal': dailyGoal,
  };
}

/// Complete tracking data for a student on a specific day
final class StudentTrackingData {
  const StudentTrackingData({
    required this.trackingId,
    required this.studentId,
    required this.trackingDate,
    required this.ibadaat,
    required this.quran,
    required this.habits,
    required this.studySessions,
  });

  final String trackingId;
  final String studentId;
  final DateTime trackingDate;
  final IbadaatData ibadaat;
  final QuranData quran;
  final List<HabitTrackingData> habits;
  final List<StudySessionData> studySessions;

  /// Calculate overall progress as percentage (0-1)
  double calculateProgress() {
    final ibadaatScore = IbadaatData.totalCount > 0
        ? ibadaat.completedCount / IbadaatData.totalCount
        : 0.0;
    final quranScore = (quran.reviewed || quran.memorized) ? 1.0 : 0.0;
    final habitsScore = habits.isNotEmpty
        ? habits.where((h) => h.completed).length / habits.length
        : 0.0;
    final studyScore = studySessions.isNotEmpty
        ? studySessions.fold(0.0, (sum, s) => sum + s.progress) /
              studySessions.length
        : 0.0;

    // Average of 4 categories
    return (ibadaatScore + quranScore + habitsScore + studyScore) / 4;
  }

  factory StudentTrackingData.fromJson(Map<String, dynamic> json) {
    final habitsJson = json['habits'] as List<dynamic>? ?? [];
    final studyJson = json['study_sessions'] as List<dynamic>? ?? [];

    return StudentTrackingData(
      trackingId: json['id'] as String,
      studentId: json['student_id'] as String,
      trackingDate: DateTime.parse(json['tracking_date'] as String? ?? ''),
      ibadaat: IbadaatData.fromJson(
        json['ibadaat'] as Map<String, dynamic>? ?? {},
      ),
      quran: QuranData.fromJson(json['quran'] as Map<String, dynamic>? ?? {}),
      habits: habitsJson
          .whereType<Map<String, dynamic>>()
          .map(HabitTrackingData.fromJson)
          .toList(),
      studySessions: studyJson
          .whereType<Map<String, dynamic>>()
          .map(StudySessionData.fromJson)
          .toList(),
    );
  }
}

/// Student profile data
final class StudentProfileData {
  const StudentProfileData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarIndex,
    required this.grade,
    required this.groupName,
    required this.currentStreak,
    required this.notes,
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
