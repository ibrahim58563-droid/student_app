import 'package:students_app/features/tracking/data/data_sources/tracking_remote_data_source.dart';
import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/domain/repositories/tracking_repository.dart';

final class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._remoteDataSource);

  final TrackingRemoteDataSource _remoteDataSource;

  @override
  Future<DailyTracking> fetchTracking(String studentId, DateTime date) =>
      _remoteDataSource.fetchTracking(studentId, date);

  @override
  Future<void> updateIbadaatField(
    String trackingId,
    String field,
    bool value,
  ) => _remoteDataSource.updateIbadaatField(trackingId, field, value);

  @override
  Future<void> updateQuran(String trackingId, Map<String, dynamic> data) =>
      _remoteDataSource.updateQuran(trackingId, data);

  @override
  Future<void> toggleHabit(String habitId, bool value) =>
      _remoteDataSource.toggleHabit(habitId, value);

  @override
  Future<void> upsertStudySession(String trackingId, StudySession session) =>
      _remoteDataSource.upsertStudySession(trackingId, session);
}
