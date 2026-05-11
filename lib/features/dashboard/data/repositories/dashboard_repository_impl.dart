import 'package:students_app/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:students_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:students_app/features/dashboard/domain/repositories/dashboard_repository.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remoteDataSource);

  final DashboardRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardSummary> getSummary() async {
    final map = await _remoteDataSource.fetchSummary();
    return DashboardSummary(
      totalStudents: map['totalStudents'] ?? 0,
      todayAttendance: map['todayAttendance'] ?? 0,
      completedTracking: map['completedTracking'] ?? 0,
    );
  }
}
