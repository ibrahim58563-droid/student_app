import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';

class HabitsCard extends ConsumerWidget {
  const HabitsCard({
    required this.tracking,
    required this.studentId,
    required this.isAdmin,
    super.key,
  });

  final StudentTrackingData tracking;
  final String studentId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(studentTrackingProvider(studentId)).isLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== Header ==========
            Text(
              '✨ العادات الحسنة',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // ========== Habits Grid ==========
            if (tracking.habits.isEmpty)
              Center(
                child: Text(
                  'لا توجد عادات معرفة بعد',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tracking.habits.map((habit) {
                  final isCompleted = habit.completed;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            await ref
                                .read(
                                  studentTrackingProvider(studentId).notifier,
                                )
                                .toggleHabit(habit.habitId);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : Colors.transparent,
                        border: isCompleted
                            ? null
                            : Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        habit.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isCompleted
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
