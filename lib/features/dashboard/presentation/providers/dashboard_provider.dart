import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:students_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:students_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:students_app/features/dashboard/domain/use_cases/get_dashboard_summary_use_case.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  final remoteDataSource = DashboardRemoteDataSource();
  final repository = DashboardRepositoryImpl(remoteDataSource);
  final useCase = GetDashboardSummaryUseCase(repository);
  return useCase();
});
