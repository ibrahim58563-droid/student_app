import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:students_app/features/students/data/repositories/student_profile_repository.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Student profile repository provider.
final studentProfileRepositoryProvider = Provider<StudentProfileRepository>((
  ref,
) {
  return StudentProfileRepository(Supabase.instance.client);
});

/// Student profile data provider.
final studentProfileProvider =
    FutureProvider.family<StudentProfileData, String>((ref, studentId) async {
      final repository = ref.watch(studentProfileRepositoryProvider);
      return repository.fetchStudentProfile(studentId);
    });

/// Student tracking provider with optimistic updates.
final studentTrackingProvider =
    StateNotifierProvider.family<
      StudentTrackingNotifier,
      AsyncValue<StudentTrackingData>,
      String
    >((ref, studentId) {
      final repository = ref.watch(studentProfileRepositoryProvider);
      return StudentTrackingNotifier(studentId, repository);
    });

final class StudentTrackingNotifier
    extends StateNotifier<AsyncValue<StudentTrackingData>> {
  StudentTrackingNotifier(this._studentId, this._repository)
    : super(const AsyncValue.loading()) {
    _loadInitialTracking();
  }

  final String _studentId;
  final StudentProfileRepository _repository;

  Future<void> _loadInitialTracking() async {
    state = await AsyncValue.guard(
      () => _repository.fetchTodayTracking(_studentId),
    );
  }

  Future<StudentProfileData> loadStudentProfile(String studentId) {
    return _repository.fetchStudentProfile(studentId);
  }

  Future<StudentTrackingData> loadTodayTracking(
    String studentId,
    DateTime date,
  ) {
    return _repository.fetchTodayTracking(studentId);
  }

  Future<void> updateIbadaat(String field, bool value) async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    state = AsyncData(
      StudentTrackingData(
        trackingId: current.trackingId,
        studentId: current.studentId,
        trackingDate: current.trackingDate,
        ibadaat: IbadaatData(
          fajr: field == 'fajr' ? value : current.ibadaat.fajr,
          dhuhr: field == 'dhuhr' ? value : current.ibadaat.dhuhr,
          asr: field == 'asr' ? value : current.ibadaat.asr,
          maghrib: field == 'maghrib' ? value : current.ibadaat.maghrib,
          isha: field == 'isha' ? value : current.ibadaat.isha,
          morningAdhkar: field == 'morning_adhkar'
              ? value
              : current.ibadaat.morningAdhkar,
          eveningAdhkar: field == 'evening_adhkar'
              ? value
              : current.ibadaat.eveningAdhkar,
        ),
        quran: current.quran,
        habits: current.habits,
        studySessions: current.studySessions,
      ),
    );

    try {
      await _repository.updateIbadaat(current.trackingId, field, value);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateQuran(Map<String, dynamic> updates) async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    state = AsyncData(
      StudentTrackingData(
        trackingId: current.trackingId,
        studentId: current.studentId,
        trackingDate: current.trackingDate,
        ibadaat: current.ibadaat,
        quran: QuranData(
          currentSurah:
              updates['current_surah'] as String? ?? current.quran.currentSurah,
          pages: updates['pages'] as int? ?? current.quran.pages,
          reviewed: updates['reviewed'] as bool? ?? current.quran.reviewed,
          memorized: updates['memorized'] as bool? ?? current.quran.memorized,
        ),
        habits: current.habits,
        studySessions: current.studySessions,
      ),
    );

    try {
      await _repository.updateQuran(current.trackingId, updates);
      state = await AsyncValue.guard(
        () => _repository.fetchTodayTracking(_studentId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleHabit(String habitId) async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    final updatedHabits = current.habits
        .map(
          (habit) => HabitTrackingData(
            habitId: habit.habitId,
            name: habit.name,
            completed: habit.habitId == habitId
                ? !habit.completed
                : habit.completed,
          ),
        )
        .toList();

    state = AsyncData(
      StudentTrackingData(
        trackingId: current.trackingId,
        studentId: current.studentId,
        trackingDate: current.trackingDate,
        ibadaat: current.ibadaat,
        quran: current.quran,
        habits: updatedHabits,
        studySessions: current.studySessions,
      ),
    );

    try {
      await _repository.toggleHabit(current.trackingId, habitId);
      state = await AsyncValue.guard(
        () => _repository.fetchTodayTracking(_studentId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateStudySession(
    String subject,
    double hours,
    double goal,
  ) async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    final updatedSessions = <StudySessionData>[];
    var found = false;

    for (final session in current.studySessions) {
      if (session.subject == subject) {
        updatedSessions.add(
          StudySessionData(
            subject: subject,
            hoursSpent: hours,
            dailyGoal: goal,
          ),
        );
        found = true;
      } else {
        updatedSessions.add(session);
      }
    }

    if (!found) {
      updatedSessions.add(
        StudySessionData(subject: subject, hoursSpent: hours, dailyGoal: goal),
      );
    }

    state = AsyncData(
      StudentTrackingData(
        trackingId: current.trackingId,
        studentId: current.studentId,
        trackingDate: current.trackingDate,
        ibadaat: current.ibadaat,
        quran: current.quran,
        habits: current.habits,
        studySessions: updatedSessions,
      ),
    );

    try {
      await _repository.updateStudySession(
        current.trackingId,
        subject,
        hours,
        goal,
      );
      state = await AsyncValue.guard(
        () => _repository.fetchTodayTracking(_studentId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
