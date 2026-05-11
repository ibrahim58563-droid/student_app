import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';

class StudyCard extends ConsumerStatefulWidget {
  const StudyCard({
    required this.tracking,
    required this.studentId,
    required this.isAdmin,
    super.key,
  });

  final StudentTrackingData tracking;
  final String studentId;
  final bool isAdmin;

  @override
  ConsumerState<StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends ConsumerState<StudyCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> subjects = ['History', 'Physics', 'Mathematics'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: subjects.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  StudySessionData? _getSessionForSubject(String subject) {
    try {
      return widget.tracking.studySessions.firstWhere(
        (s) => s.subject == subject,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref
        .watch(studentTrackingProvider(widget.studentId))
        .isLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== Header ==========
            Text(
              '🎓 الدراسة',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // ========== Subject Tabs ==========
            Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                controller: _tabController,
                labelStyle: Theme.of(context).textTheme.labelSmall,
                tabs: subjects.map((subject) => Tab(text: subject)).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ========== Tab Content ==========
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: subjects.map((subject) {
                  final session = _getSessionForSubject(subject);
                  final hoursSpent = session?.hoursSpent ?? 0.0;
                  final dailyGoal = session?.dailyGoal ?? 2.0;
                  final progress = (hoursSpent / dailyGoal).clamp(0, 1);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          // Progress display
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الوقت المستغرق',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                Text(
                                  '${hoursSpent.toStringAsFixed(1)}/${dailyGoal.toStringAsFixed(1)} ساعات',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.accentGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: progress.toDouble(),
                              minHeight: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0
                                    ? AppColors.accentGreen
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Slider for hours input
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Column(
                              children: [
                                Text(
                                  'اضبط الساعات',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: hoursSpent,
                                  min: 0,
                                  max: 5,
                                  divisions: 10,
                                  label: hoursSpent.toStringAsFixed(1),
                                  onChanged: isLoading
                                      ? null
                                      : (value) async {
                                          await ref
                                              .read(
                                                studentTrackingProvider(
                                                  widget.studentId,
                                                ).notifier,
                                              )
                                              .updateStudySession(
                                                subject,
                                                value,
                                                dailyGoal,
                                              );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
