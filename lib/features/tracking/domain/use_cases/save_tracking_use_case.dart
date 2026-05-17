import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/domain/repositories/tracking_repository.dart';

final class SaveTrackingUseCase {
  const SaveTrackingUseCase(this._repository);

  final TrackingRepository _repository;

  Future<void> call(DailyTracking tracking) async {
    final existing = await _repository.fetchTracking(
      tracking.studentId,
      tracking.date,
    );
    final trackingId = existing.trackingId;

    if (trackingId == null) {
      throw StateError('Tracking ID is required after fetchTracking call.');
    }

    await Future.wait([
      _repository.updateIbadaatField(trackingId, 'fajr', tracking.ibadaat.fajr),
      _repository.updateIbadaatField(
        trackingId,
        'dhuhr',
        tracking.ibadaat.dhuhr,
      ),
      _repository.updateIbadaatField(trackingId, 'asr', tracking.ibadaat.asr),
      _repository.updateIbadaatField(
        trackingId,
        'maghrib',
        tracking.ibadaat.maghrib,
      ),
      _repository.updateIbadaatField(trackingId, 'isha', tracking.ibadaat.isha),
      _repository.updateIbadaatField(
        trackingId,
        'morning_adhkar',
        tracking.ibadaat.morningAdhkar,
      ),
      _repository.updateIbadaatField(
        trackingId,
        'evening_adhkar',
        tracking.ibadaat.eveningAdhkar,
      ),
      _repository.updateQuran(trackingId, {
        'current_surah': tracking.quran.currentSurah,
        'hifz_pages': tracking.quran.hifzPages,
        'revision_pages': tracking.quran.revisionPages,
        'tilawah_done': tracking.quran.tilawahDone,
      }),
    ]);

    for (final habit in tracking.habits) {
      final habitId = habit.id;
      if (habitId == null) {
        continue;
      }
      await _repository.toggleHabit(habitId, habit.isCompleted);
    }

    for (final session in tracking.studySessions) {
      await _repository.upsertStudySession(trackingId, session);
    }
  }
}
