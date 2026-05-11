import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/tracking/data/data_sources/tracking_remote_data_source.dart';
import 'package:students_app/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/domain/use_cases/save_tracking_use_case.dart';

final trackingControllerProvider =
    AsyncNotifierProvider<TrackingController, void>(TrackingController.new);

final class TrackingController extends AsyncNotifier<void> {
  late final SaveTrackingUseCase _saveTrackingUseCase;

  @override
  Future<void> build() async {
    final remoteDataSource = TrackingRemoteDataSource();
    final repository = TrackingRepositoryImpl(remoteDataSource);
    _saveTrackingUseCase = SaveTrackingUseCase(repository);
  }

  Future<void> save(DailyTracking tracking) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _saveTrackingUseCase(tracking));
  }
}
