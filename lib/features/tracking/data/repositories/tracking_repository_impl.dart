import 'package:students_app/features/tracking/data/data_sources/tracking_remote_data_source.dart';
import 'package:students_app/features/tracking/data/models/daily_tracking_model.dart';
import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/domain/repositories/tracking_repository.dart';

final class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._remoteDataSource);

  final TrackingRemoteDataSource _remoteDataSource;

  @override
  Future<void> saveTracking(DailyTracking tracking) {
    final model = DailyTrackingModel(
      studentId: tracking.studentId,
      date: tracking.date,
      prayerScore: tracking.prayerScore,
      quranMemorizationPages: tracking.quranMemorizationPages,
      quranReviewPages: tracking.quranReviewPages,
      studyMinutes: tracking.studyMinutes,
    );
    return _remoteDataSource.saveDailyTracking(model);
  }
}
