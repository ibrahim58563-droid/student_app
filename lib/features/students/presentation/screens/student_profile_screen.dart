import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/core/constants/app_strings.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';
import 'package:students_app/features/students/presentation/widgets/habits_card.dart';
import 'package:students_app/features/students/presentation/widgets/ibadaat_card.dart';
import 'package:students_app/features/students/presentation/widgets/quran_card.dart';
import 'package:students_app/features/students/presentation/widgets/study_card.dart';
import 'package:students_app/features/students/presentation/widgets/weekly_progress_chart.dart';

/// Student profile screen - shows student's daily tracking with editing capabilities
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({required this.studentId, super.key});

  final String studentId;
  static const String routeName = 'student-profile';
  static const String routePath = '/student/profile/:studentId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(studentProfileProvider(studentId));
    final trackingState = ref.watch(studentTrackingProvider(studentId));
    final weeklyProgressState = ref.watch(weeklyProgressProvider(studentId));

    // Determine if current user is admin (viewing another student) or student (viewing self)
    final isAdmin = authState.maybeWhen(
      data: (user) => user?.role == UserRole.admin,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بيانات التتبع'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: profileState.when(
          data: (profile) => trackingState.when(
            data: (tracking) =>
                _buildContent(
                  context,
                  profile,
                  tracking,
                  weeklyProgressState,
                  isAdmin,
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('خطأ في تحميل البيانات: $err')),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StudentProfileData profile,
    StudentTrackingData tracking,
    AsyncValue<Map<DateTime, double>> weeklyProgressState,
    bool isAdmin,
  ) {
    final progress = tracking.calculateProgress();
    final progressPercent = (progress * 100).round();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 12.0 : 16.0;
    final avatarSize = screenWidth < 380 ? 84.0 : 100.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ========== Header Section ==========
          Container(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar with Streak Badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Avatar circle
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: _getAvatarColor(profile.avatarIndex),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Streak badge
                      if (profile.currentStreak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Day ${profile.currentStreak} 🔥',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Grade + Group subtitle
                  if (profile.grade != null || profile.groupName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        profile.grade,
                        profile.groupName,
                      ].whereType<String>().join(' • '),
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.progressToday,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                            Text(
                              '$progressPercent%',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF66BB6A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ========== Weekly Progress ==========
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.weeklyProgress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    weeklyProgressState.when(
                      data: (weeklyProgress) => WeeklyProgressChart(
                        progressByDay: weeklyProgress,
                      ),
                      loading: () => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stackTrace) => SizedBox(
                        height: 220,
                        child: Center(
                          child: Text(
                            'تعذر تحميل الرسم البياني',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ========== Tracking Cards ==========
          IbadaatCard(
            tracking: tracking,
            studentId: studentId,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 8),

          QuranCard(tracking: tracking, studentId: studentId, isAdmin: isAdmin),
          const SizedBox(height: 8),

          HabitsCard(
            tracking: tracking,
            studentId: studentId,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 8),

          StudyCard(tracking: tracking, studentId: studentId, isAdmin: isAdmin),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF8E44AD), // Purple
      Color(0xFF3498DB), // Blue
      Color(0xFF1ABC9C), // Teal
      Color(0xFFE74C3C), // Red
      Color(0xFFF39C12), // Orange
      Color(0xFF27AE60), // Green
    ];
    return colors[index % colors.length];
  }
}
