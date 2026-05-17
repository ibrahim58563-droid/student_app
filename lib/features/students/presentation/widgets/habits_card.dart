import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitsCard extends ConsumerStatefulWidget {
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
  ConsumerState<HabitsCard> createState() => _HabitsCardState();
}

class _HabitsCardState extends ConsumerState<HabitsCard> {
  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final habitName = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عادة جديدة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثال: قراءة، رياضة...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (habitName == null || habitName.isEmpty) return;
    if (widget.tracking.trackingId.isEmpty) return;

    try {
      await Supabase.instance.client.from('habits').insert({
        'tracking_id': widget.tracking.trackingId,
        'habit_name': habitName,
        'is_completed': false,
      });
      ref.invalidate(studentTrackingProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الإضافة: $e')));
      }
    }
  }

  Future<void> _removeHabit(String habitId) async {
    if (habitId.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف العادة'),
          content: const Text('هل تريد حذف هذه العادة نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('habits').delete().eq('id', habitId);
      ref.invalidate(studentTrackingProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
      }
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
            // Header
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✨ العادات الحسنة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      onPressed: _addHabit,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      tooltip: 'إضافة عادة',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Habits list
            if (widget.tracking.habits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.isAdmin
                        ? 'اضغط + لإضافة عادات'
                        : 'لا توجد عادات معرفة بعد',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: widget.tracking.habits.map((habit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          // Checkbox
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => ref
                                      .read(
                                        studentTrackingProvider(
                                          widget.studentId,
                                        ).notifier,
                                      )
                                      .toggleHabit(habit.habitId),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: habit.completed
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: habit.completed
                                      ? AppColors.primary
                                      : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: habit.completed
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name
                          Expanded(
                            child: Text(
                              habit.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),

                          // Delete (admin only)
                          if (widget.isAdmin && habit.habitId.isNotEmpty)
                            GestureDetector(
                              onTap: () => _removeHabit(habit.habitId),
                              child: Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: Colors.red.shade300,
                              ),
                            ),
                        ],
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
