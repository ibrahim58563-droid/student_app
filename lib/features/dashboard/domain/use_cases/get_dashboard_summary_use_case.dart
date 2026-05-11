import 'package:students_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:students_app/features/dashboard/domain/repositories/dashboard_repository.dart';

final class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> call() {
    return _repository.getSummary();
  }
}
