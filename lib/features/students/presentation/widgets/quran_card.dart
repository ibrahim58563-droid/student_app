import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';

class QuranCard extends ConsumerWidget {
  const QuranCard({
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
              '📖 القرآن الكريم',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // ========== Surah Name ==========
            if (tracking.quran.currentSurah != null) ...[
              Text(
                tracking.quran.currentSurah!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Pages count
            Text(
              'الصفحات: ${tracking.quran.pages}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ========== Action Buttons ==========
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(studentTrackingProvider(studentId).notifier)
                                  .updateQuran({
                                    'reviewed': !tracking.quran.reviewed,
                                  });
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: tracking.quran.reviewed
                            ? AppColors.accentGreen
                            : AppColors.divider,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tracking.quran.reviewed ? '✓' : '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('مراجعة'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(studentTrackingProvider(studentId).notifier)
                                  .updateQuran({
                                    'memorized': !tracking.quran.memorized,
                                  });
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: tracking.quran.memorized
                            ? AppColors.accentGreen
                            : AppColors.divider,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tracking.quran.memorized ? '★' : '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('حفظ'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
