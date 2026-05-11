import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/core/constants/app_strings.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/core/widgets/global_error_widget.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:students_app/features/dashboard/presentation/widgets/student_card.dart';
import 'package:students_app/features/dashboard/presentation/widgets/student_card_shimmer.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  static const String routeName = 'students-list';
  static const String routePath = '/students';

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
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
    final selectedGroup = ref.watch(groupFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.studentsTitle),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ========== Search Bar ==========
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding(context)),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ========== Filter Chips ==========
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding(context)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
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
                                      ref.read(groupFilterProvider.notifier).setGroup(
                                          selected ? group : null);
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
            const SizedBox(height: 16),

            // ========== Students List ==========
            Expanded(
              child: studentsState.when(
                data: (students) {
                  if (students.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.noStudents,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return StudentCard(
                        student: student,
                        onTap: () {
                          context.push('/admin/students/${student.id}');
                        },
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) => const StudentCardShimmer(),
                ),
                error: (err, _) => Center(
                  child: GlobalErrorWidget.supabase(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 380 ? 12 : 16;
  }
}
