import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:students_app/features/students/presentation/screens/students_screen.dart';
import 'package:students_app/features/tracking/presentation/screens/tracking_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String routeName = 'dashboard';
  static const String routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المتابعة | Dashboard')),
      body: summaryState.when(
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'إجمالي الطلاب / Total Students',
                value: summary.totalStudents,
              ),
              _SummaryCard(
                title: 'حضور اليوم / Today Attendance',
                value: summary.todayAttendance,
              ),
              _SummaryCard(
                title: 'تقارير مكتملة / Completed Tracking',
                value: summary.completedTracking,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.go(StudentsScreen.routePath),
                child: const Text('الطلاب / Students'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.go(TrackingScreen.routePath),
                child: const Text('التتبع اليومي / Daily Tracking'),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(child: Text('حدث خطأ: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: CircleAvatar(child: Text('$value')),
      ),
    );
  }
}
