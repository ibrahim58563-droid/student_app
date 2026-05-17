import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/core/constants/app_strings.dart';
import 'package:students_app/core/widgets/global_error_widget.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:students_app/features/dashboard/presentation/widgets/student_card.dart';
import 'package:students_app/features/dashboard/presentation/widgets/student_card_shimmer.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  static const String routeName = 'admin-dashboard';
  static const String routePath = '/admin/dashboard';

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(filteredStudentsProvider);
    final groupsState = ref.watch(groupNamesProvider);
    final insightsState = ref.watch(classInsightsProvider);
    final selectedGroup = ref.watch(groupFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      // ========== Body ==========
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ========== Search Bar ==========
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding(context),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).setQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.searchStudentHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).clear();
                              },
                              child: const Icon(Icons.close, size: 20),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ========== Filter Chips ==========
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _horizontalPadding(context),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        // "الكل" chip
                        FilterChip(
                          label: const Text(AppStrings.allFilter),
                          selected: selectedGroup == null,
                          onSelected: (selected) {
                            ref.read(groupFilterProvider.notifier).reset();
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedGroup == null
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: selectedGroup == null
                                ? Colors.transparent
                                : AppColors.divider,
                          ),
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        // Dynamic group chips
                        groupsState.when(
                          data: (groups) => Row(
                            children: groups
                                .map(
                                  (group) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: FilterChip(
                                      label: Text(group),
                                      selected: selectedGroup == group,
                                      onSelected: (selected) {
                                        ref
                                            .read(groupFilterProvider.notifier)
                                            .setGroup(selected ? group : null);
                                      },
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: selectedGroup == group
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      side: BorderSide(
                                        color: selectedGroup == group
                                            ? Colors.transparent
                                            : AppColors.divider,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          loading: () => const SizedBox(width: 40, height: 32),
                          error: (err, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ========== Student Cards ==========
              studentsState.when(
                data: (students) {
                  if (students.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          AppStrings.noStudents,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: students
                        .map(
                          (student) => StudentCard(
                            student: student,
                            onTap: () {
                              context.push('/admin/students/${student.id}');
                            },
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(
                    3,
                    (index) => const StudentCardShimmer(),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlobalErrorWidget.supabase(
                    onRetry: () {
                      ref.invalidate(filteredStudentsProvider);
                      ref.invalidate(groupNamesProvider);
                      ref.invalidate(classInsightsProvider);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ========== Class Insights ==========
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding(context),
                ),
                child: Text(
                  AppStrings.classOverview,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              insightsState.when(
                data: (insights) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _horizontalPadding(context),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InsightCard(
                        title: AppStrings.averageProgress,
                        value:
                            '${(insights.averageProgress * 100).toStringAsFixed(1)}%',
                        valueColor: AppColors.accentGreen,
                      ),
                      _InsightCard(
                        title: AppStrings.topStreak,
                        value: '${insights.topStreak}',
                        suffix: AppStrings.days,
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: StudentCardShimmer(),
                ),
                error: (err, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      // ========== FAB ==========
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('edit');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 380 ? 12 : 16;
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.valueColor,
    this.suffix,
  });

  final String title;
  final String value;
  final String? suffix;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
