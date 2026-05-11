final class DailyTrackingData {
  const DailyTrackingData({
    required this.date,
    required this.completedPrayers,
    required this.completedAdhkar,
    required this.hifzPages,
    required this.revisionPages,
    required this.completedHabits,
    required this.totalHabits,
    required this.hoursSpent,
    required this.dailyGoal,
  });

  final DateTime date;
  final int completedPrayers;
  final int completedAdhkar;
  final int hifzPages;
  final int revisionPages;
  final int completedHabits;
  final int totalHabits;
  final double hoursSpent;
  final double dailyGoal;

  factory DailyTrackingData.fromJson(Map<String, dynamic> json) {
    final trackingDate = _parseDate(json['tracking_date'] ?? json['date']) ??
        DateTime.now();

    final ibadaat = _asMap(json['ibadaat']);
    final quran = _asMap(json['quran']);
    final habits = _asList(json['habits']);
    final studySessions = _asList(json['study_sessions']);

    final prayerKeys = [
      'fajr',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    ];
    final adhkarKeys = ['morning_adhkar', 'evening_adhkar'];

    final completedPrayers = prayerKeys.where((key) {
      return _readBool(ibadaat[key]) ?? _readBool(json[key]) ?? false;
    }).length;

    final completedAdhkar = adhkarKeys.where((key) {
      return _readBool(ibadaat[key]) ?? _readBool(json[key]) ?? false;
    }).length;

    final hifzPages = _readInt(
          quran['hifz_pages'],
        ) ??
        _readInt(quran['memorization_pages']) ??
        _readInt(quran['quran_memorization_pages']) ??
        _readInt(json['hifz_pages']) ??
        _readInt(json['quran_memorization_pages']) ??
        0;

    final revisionPages = _readInt(
          quran['revision_pages'],
        ) ??
        _readInt(quran['review_pages']) ??
        _readInt(quran['quran_review_pages']) ??
        _readInt(json['revision_pages']) ??
        _readInt(json['quran_review_pages']) ??
        0;

    var completedHabits = 0;
    var totalHabits = 0;

    if (habits.isNotEmpty) {
      totalHabits = habits.length;
      completedHabits = habits.where((item) {
        final habitMap = _asMap(item);
        return _readBool(habitMap['completed']) ?? _readBool(habitMap['is_completed']) ?? false;
      }).length;
    } else {
      completedHabits = _readInt(json['completed_habits']) ?? 0;
      totalHabits = _readInt(json['total_habits']) ?? 0;
    }

    var hoursSpent = 0.0;
    var dailyGoal = 0.0;

    if (studySessions.isNotEmpty) {
      final sessionMap = _asMap(studySessions.first);
      hoursSpent = _readDouble(sessionMap['hours_spent']) ?? 0.0;
      dailyGoal = _readDouble(sessionMap['daily_goal']) ?? 0.0;
    } else {
      hoursSpent = _readDouble(json['hours_spent']) ??
          _readDouble(json['study_hours']) ??
          0.0;
      dailyGoal = _readDouble(json['daily_goal']) ??
          _readDouble(json['study_goal']) ??
          0.0;
    }

    return DailyTrackingData(
      date: trackingDate,
      completedPrayers: completedPrayers,
      completedAdhkar: completedAdhkar,
      hifzPages: hifzPages,
      revisionPages: revisionPages,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      hoursSpent: hoursSpent,
      dailyGoal: dailyGoal,
    );
  }
}

double calculateDailyProgress(DailyTrackingData data) {
  final ibadaatScore =
      (data.completedPrayers + data.completedAdhkar).clamp(0, 7) / 7.0;
  final quranScore =
      (data.hifzPages > 0 ? 0.5 : 0.0) + (data.revisionPages > 0 ? 0.5 : 0.0);
  final habitsScore = data.totalHabits > 0
      ? (data.completedHabits / data.totalHabits).clamp(0.0, 1.0)
      : 0.0;
  final studyScore = data.dailyGoal > 0
      ? (data.hoursSpent >= data.dailyGoal
          ? 1.0
          : (data.hoursSpent / data.dailyGoal).clamp(0.0, 1.0))
      : 0.0;

  return (ibadaatScore + quranScore + habitsScore + studyScore) / 4.0;
}

int calculateStreak(List<DailyTrackingData> history) {
  if (history.isEmpty) {
    return 0;
  }

  final byDate = {
    for (final entry in history) _dateOnly(entry.date): entry,
  };

  var streak = 0;
  final today = _dateOnly(DateTime.now());

  for (var offset = 0; offset < 365; offset++) {
    final date = today.subtract(Duration(days: offset));
    final tracking = byDate[date];

    if (tracking == null) {
      break;
    }

    if (calculateDailyProgress(tracking) >= 0.5) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

String getProgressLabel(double progress) {
  if (progress >= 0.8) {
    return 'ممتاز 🌟';
  }
  if (progress >= 0.6) {
    return 'جيد جداً 👍';
  }
  if (progress >= 0.4) {
    return 'جيد';
  }
  return 'يحتاج متابعة';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return const {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return List<dynamic>.from(value);
  }
  return const [];
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}