/// Lightweight model for dashboard student cards
final class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.fullName,
    required this.avatarIndex,
    required this.grade,
    required this.groupName,
    required this.todayProgress,
    required this.currentStreak,
    required this.tasksCompleted,
    required this.totalTasks,
  });

  final String id;
  final String fullName;
  final int avatarIndex;
  final String? grade;
  final String? groupName;

  /// Progress 0.0 to 1.0
  final double todayProgress;

  /// Consecutive days of 100% progress
  final int currentStreak;

  /// Tasks completed today (e.g., 5)
  final int tasksCompleted;

  /// Total tasks possible (e.g., 7)
  final int totalTasks;

  /// Progress as percentage (0-100)
  int get progressPercent => (todayProgress * 100).round();
}
