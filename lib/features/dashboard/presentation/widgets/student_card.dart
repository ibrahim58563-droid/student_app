import 'package:flutter/material.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/dashboard/domain/models/student_summary.dart';

/// Reusable student progress card
class StudentCard extends StatelessWidget {
  const StudentCard({required this.student, this.onTap, super.key});

  final StudentSummary student;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarColors = [
      const Color(0xFF1B5E20),
      const Color(0xFF2E7D32),
      const Color(0xFF5E9E20),
      const Color(0xFFE1B700),
      const Color(0xFFF57C00),
      const Color(0xFF0097A7),
    ];

    final avatarColor = avatarColors[student.avatarIndex % avatarColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // == Head: Avatar + Name + Badge ==
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Progress %
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (student.groupName != null)
                          Text(
                            student.groupName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  // Progress Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${student.progressPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // == Progress Bar ==
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: student.todayProgress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGreen,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // == Task Subtitle ==
              Text(
                'أكمل ${student.tasksCompleted}/${student.totalTasks} مهمة اليوم',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
