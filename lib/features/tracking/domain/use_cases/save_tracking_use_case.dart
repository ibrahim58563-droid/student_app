import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/domain/repositories/tracking_repository.dart';

final class SaveTrackingUseCase {
  const SaveTrackingUseCase(this._repository);

  final TrackingRepository _repository;

  Future<void> call(DailyTracking tracking) {
    return _repository.saveTracking(tracking);
  }
}
