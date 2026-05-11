import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:students_app/features/dashboard/domain/models/student_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

/// Group filter notifier
final class GroupFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setGroup(String? group) {
    state = group;
  }

  void reset() {
    state = null;
  }
}

/// Selected group filter state
final groupFilterProvider = NotifierProvider<GroupFilterNotifier, String?>(
  GroupFilterNotifier.new,
);

/// Search query notifier
final class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Search query state
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// All students with progress
final allStudentsProvider = FutureProvider<List<StudentSummary>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final groupFilter = ref.watch(groupFilterProvider);
  return repo.fetchAllStudents(groupFilter: groupFilter);
});

/// Filtered and searched students
final filteredStudentsProvider = FutureProvider<List<StudentSummary>>((
  ref,
) async {
  final students = await ref.watch(allStudentsProvider.future);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return students;
  }

  return students
      .where((s) => s.fullName.toLowerCase().contains(searchQuery))
      .toList();
});

/// Available group names for filter chips
final groupNamesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchGroupNames();
});

/// Class insights (average progress + streak)
final classInsightsProvider = FutureProvider((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchClassInsights();
});

/// Weekly progress for the student profile chart.
final weeklyProgressProvider =
    FutureProvider.family<Map<DateTime, double>, String>((ref, studentId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchWeeklyProgress(studentId);
});
