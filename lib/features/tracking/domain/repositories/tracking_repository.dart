import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';

abstract interface class TrackingRepository {
  Future<void> saveTracking(DailyTracking tracking);
}
