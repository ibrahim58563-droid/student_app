import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:students_app/features/dashboard/presentation/widgets/student_card_shimmer.dart';

class StudentRegistryScreen extends ConsumerStatefulWidget {
  const StudentRegistryScreen({super.key});

  static const String routeName = 'student-registry';
  static const String routePath = '/admin/students';

  @override
  ConsumerState<StudentRegistryScreen> createState() =>
      _StudentRegistryScreenState();
}

class _StudentRegistryScreenState extends ConsumerState<StudentRegistryScreen> {
  final _searchController = TextEditingController();
  bool _activeOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(filteredStudentsProvider);
    final insightsState = ref.watch(classInsightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE6),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'The Archivist',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Student Registry',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cultivating wisdom through disciplined study.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search
                    const Text(
                      'FIND SCHOLAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).setQuery(v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or cohort...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        suffixIcon: const Icon(Icons.search, size: 20),
                        filled: false,
                        border: const UnderlineInputBorder(),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All Cohorts',
                          selected: !_activeOnly,
                          onTap: () => setState(() => _activeOnly = false),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Active Only',
                          selected: _activeOnly,
                          onTap: () => setState(() => _activeOnly = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Student List ─────────────────────────
            studentsState.when(
              data: (students) => SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final student = students[index];
                  return _StudentRegistryCard(
                    name: student.fullName,
                    subtitle: [
                      student.grade,
                      student.groupName,
                    ].whereType<String>().join(' • '),
                    masteryPercent: student.progressPercent,
                    avatarIndex: student.avatarIndex,
                    onTap: () => context.push('/admin/students/${student.id}'),
                  );
                }, childCount: students.length),
              ),
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const StudentCardShimmer(),
                  childCount: 4,
                ),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('خطأ: $e'))),
            ),

            // ── Class Insights ───────────────────────────
            SliverToBoxAdapter(
              child: insightsState.when(
                data: (insights) => Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A2D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'AVERAGE PROGRESS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(insights.averageProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ENGAGEMENT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < 4 ? Icons.star : Icons.star_half,
                            color: const Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 200),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      // FAB - Add Student
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/students/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('إضافة طالب', style: TextStyle(color: Colors.white)),
      ),

      // Bottom Navigation
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StudentRegistryCard extends StatelessWidget {
  const _StudentRegistryCard({
    required this.name,
    required this.subtitle,
    required this.masteryPercent,
    required this.avatarIndex,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final int masteryPercent;
  final int avatarIndex;
  final VoidCallback onTap;

  static const _avatarColors = [
    Color(0xFF8E44AD),
    Color(0xFF3498DB),
    Color(0xFF1ABC9C),
    Color(0xFFE74C3C),
    Color(0xFFF39C12),
    Color(0xFF27AE60),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[avatarIndex % _avatarColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  // Avatar (arched style)
                  Container(
                    width: 64,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withAlpha((255 * 0.15).toInt()),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Mastery %
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'MASTERY\nLEVEL',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$masteryPercent%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE6),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.grid_view,
            label: 'DASHBOARD',
            index: 0,
            currentIndex: currentIndex,
            onTap: () => context.go('/admin/dashboard'),
          ),
          _NavItem(
            icon: Icons.people,
            label: 'STUDENTS',
            index: 1,
            currentIndex: currentIndex,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'PROFILE',
            index: 2,
            currentIndex: currentIndex,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'SETTINGS',
            index: 3,
            currentIndex: currentIndex,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppColors.primary : Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
