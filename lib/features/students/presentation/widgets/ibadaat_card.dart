import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';

class IbadaatCard extends ConsumerWidget {
  const IbadaatCard({
    required this.tracking,
    required this.studentId,
    required this.isAdmin,
    super.key,
  });

  final StudentTrackingData tracking;
  final String studentId;
  final bool isAdmin;

  static const List<({String key, String arabicName, String englishName})>
  prayers = [
    (key: 'fajr', arabicName: 'الفجر', englishName: 'Fajr'),
    (key: 'dhuhr', arabicName: 'الظهر', englishName: 'Dhuhr'),
    (key: 'asr', arabicName: 'العصر', englishName: 'Asr'),
    (key: 'maghrib', arabicName: 'المغرب', englishName: 'Maghrib'),
    (key: 'isha', arabicName: 'العشاء', englishName: 'Isha'),
    (
      key: 'morning_adhkar',
      arabicName: 'أذكار الصباح',
      englishName: 'Morning Adhkar',
    ),
    (
      key: 'evening_adhkar',
      arabicName: 'أذكار المساء',
      englishName: 'Evening Adhkar',
    ),
  ];

  bool _isPrayerCompleted(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return tracking.ibadaat.fajr;
      case 'dhuhr':
        return tracking.ibadaat.dhuhr;
      case 'asr':
        return tracking.ibadaat.asr;
      case 'maghrib':
        return tracking.ibadaat.maghrib;
      case 'isha':
        return tracking.ibadaat.isha;
      case 'morning_adhkar':
        return tracking.ibadaat.morningAdhkar;
      case 'evening_adhkar':
        return tracking.ibadaat.eveningAdhkar;
      default:
        return false;
    }
  }

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
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🕌 عبادات',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tracking.ibadaat.completedCount}/${IbadaatData.totalCount}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== Prayer Rows ==========
            Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: prayers.map((prayer) {
                  final isCompleted = _isPrayerCompleted(prayer.key);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              await ref
                              .read(studentTrackingProvider(studentId).notifier)
                                  .updateIbadaat(prayer.key, !isCompleted);
                            },
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: isCompleted
                                  ? null
                                  : Border.all(
                                      color: AppColors.divider,
                                      width: 1.5,
                                    ),
                              color: isCompleted
                                  ? AppColors.accentGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prayer.arabicName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: isCompleted
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                ),
                                Text(
                                  prayer.englishName,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
