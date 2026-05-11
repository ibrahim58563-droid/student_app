final class DashboardRemoteDataSource {
  const DashboardRemoteDataSource();

  Future<Map<String, int>> fetchSummary() async {
    return const {
      'totalStudents': 28,
      'todayAttendance': 22,
      'completedTracking': 17,
    };
  }
}
