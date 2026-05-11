import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/core/constants/app_strings.dart';
import 'package:students_app/core/widgets/global_error_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Student detail screen - shows individual student info and tracking
class StudentDetailScreen extends ConsumerStatefulWidget {
  const StudentDetailScreen({required this.studentId, super.key});

  final String studentId;

  static String buildPath(String studentId) => '/admin/students/$studentId';

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  late Future<Map<String, dynamic>> studentDataFuture;

  @override
  void initState() {
    super.initState();
    studentDataFuture = _fetchStudentData();
  }

  Future<Map<String, dynamic>> _fetchStudentData() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch student profile
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.studentId)
          .single();

      // Fetch today's tracking records
      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      ).toString().split(' ')[0];

      final tracking = await supabase
          .from('daily_tracking')
          .select()
          .eq('student_id', widget.studentId)
          .eq('tracking_date', today);

      return {
        'profile': profile,
        'tracking': tracking.isNotEmpty ? tracking[0] : null,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: studentDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: _CustomAppBar(title: AppStrings.loading),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: const _CustomAppBar(title: AppStrings.loadError),
            body: GlobalErrorWidget.supabase(
              onRetry: () => setState(() {
                studentDataFuture = _fetchStudentData();
              }),
            ),
          );
        }

        final data = snapshot.data!;
        final profile = data['profile'] as Map<String, dynamic>;
        final tracking = data['tracking'] as Map<String, dynamic>?;

        return Scaffold(
          appBar: _CustomAppBar(
            title: profile['full_name'] as String? ?? 'Student',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.studentInfo,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: AppStrings.name,
                              value: profile['full_name'] as String? ?? '-',
                            ),
                            _InfoRow(
                              label: AppStrings.email,
                              value: profile['email'] as String? ?? '-',
                            ),
                            if (profile['grade'] != null)
                              _InfoRow(
                                label: AppStrings.grade,
                                value: profile['grade'] as String,
                              ),
                            if (profile['group_name'] != null)
                              _InfoRow(
                                label: AppStrings.group,
                                value: profile['group_name'] as String,
                              ),
                            if (profile['notes'] != null)
                              _InfoRow(
                                label: AppStrings.notes,
                                value: profile['notes'] as String,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tracking Status
                    if (tracking != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppStrings.todayTracking} (${tracking['tracking_date']})',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.trackingSaved,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.accentGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              AppStrings.noTracking,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), centerTitle: true, elevation: 0);
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
