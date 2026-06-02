import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/features/students/presentation/screens/add_edit_student_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'daily_progress_screen.dart';

const Color primary = Color(0xFF1B5E20);
const Color background = Color(0xFFF0EDE6);
const Color cardBg = Color(0xFFEDE8DC);
const Color avatarBg = Color(0xFFCDD5C8);
const Color accent = Color(0xFFF59E0B);
const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF6B7280);

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({required this.studentId, super.key});

  final String studentId;

  static String buildPath(String studentId) => '/admin/students/$studentId';

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
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

      Map<String, dynamic>? trackingData;
      Map<String, dynamic> ibadaat = {};
      List<Map<String, dynamic>> quran = [];
      List<Map<String, dynamic>> habits = [];
      List<Map<String, dynamic>> study = [];

      if (tracking.isNotEmpty) {
        trackingData = tracking[0];
        final trackingId = trackingData['id'];

        // Fetch ibadaat data
        final ibadaatList = await supabase
            .from('ibadaat')
            .select()
            .eq('tracking_id', trackingId);

        if (ibadaatList.isNotEmpty) {
          ibadaat = ibadaatList[0];
        }

        // Fetch quran tracking data
        final quranList = await supabase
            .from('quran_tracking')
            .select()
            .eq('tracking_id', trackingId);

        quran = List<Map<String, dynamic>>.from(quranList);

        // Fetch habits data
        final habitsList = await supabase
            .from('habits')
            .select()
            .eq('tracking_id', trackingId);

        habits = List<Map<String, dynamic>>.from(habitsList);

        // Fetch study sessions data
        final studyList = await supabase
            .from('study_sessions')
            .select()
            .eq('tracking_id', trackingId);

        study = List<Map<String, dynamic>>.from(studyList);
      }

      return {
        'profile': profile,
        'tracking': trackingData,
        'ibadaat': ibadaat,
        'quran': quran,
        'habits': habits,
        'study': study,
      };
    } catch (e) {
      rethrow;
    }
  }

  int _calcProgress(
    Map<String, dynamic> ibadaat,
    List<Map<String, dynamic>> quran,
    List<Map<String, dynamic>> habits,
    List<Map<String, dynamic>> study,
  ) {
    double ibadaatScore = 0;
    if (ibadaat.isNotEmpty) {
      final ibadaatValues = [
        ibadaat['fajr'] ?? false,
        ibadaat['dhuhr'] ?? false,
        ibadaat['asr'] ?? false,
        ibadaat['maghrib'] ?? false,
        ibadaat['isha'] ?? false,
        ibadaat['morning_adhkar'] ?? false,
        ibadaat['evening_adhkar'] ?? false,
      ];
      ibadaatScore =
          ibadaatValues.where((v) => v == true).length / ibadaatValues.length;
    }

    double quranScore = 0;
    if (quran.isNotEmpty) {
      final q = quran[0];
      final hifzPages = (q['hifz_pages'] ?? 0) as int;
      final revisionPages = (q['revision_pages'] ?? 0) as int;
      if (hifzPages > 0) quranScore += 0.5;
      if (revisionPages > 0) quranScore += 0.5;
    }

    double habitsScore = 0;
    if (habits.isNotEmpty) {
      habitsScore =
          habits.where((h) => h['is_completed'] == true).length / habits.length;
    }

    double studyScore = study.isNotEmpty ? 1.0 : 0.0;

    return (((ibadaatScore + quranScore + habitsScore + studyScore) / 4) * 100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: studentDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: const _CustomAppBar(
              title: 'Loading',
              showEditButton: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: const _CustomAppBar(title: 'Error', showEditButton: false),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      studentDataFuture = _fetchStudentData();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final profile = data['profile'] as Map<String, dynamic>;
        final ibadaat = (data['ibadaat'] as Map<String, dynamic>?) ?? {};
        final quran =
            (data['quran'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        final habits =
            (data['habits'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        final study =
            (data['study'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        final tracking = data['tracking'] as Map<String, dynamic>?;

        final fullName = profile['full_name'] as String? ?? 'Student';
        final groupName = profile['group_name'] as String?;
        final grade = profile['grade'] as String?;
        final firstLetter = fullName.isNotEmpty
            ? fullName[0].toUpperCase()
            : '?';

        final progressPercent = _calcProgress(ibadaat, quran, habits, study);

        final ibadaatItems = [
          {'name': 'الفجر', 'completed': ibadaat['fajr'] ?? false},
          {'name': 'الظهر', 'completed': ibadaat['dhuhr'] ?? false},
          {'name': 'العصر', 'completed': ibadaat['asr'] ?? false},
        ];

        final quranItems = [
          {
            'name': 'حفظ',
            'completed':
                (quran.isNotEmpty && (quran[0]['hifz_pages'] ?? 0) > 0),
          },
          {
            'name': 'مراجعة',
            'completed':
                (quran.isNotEmpty && (quran[0]['revision_pages'] ?? 0) > 0),
          },
          {
            'name': 'تلاوة',
            'completed':
                (quran.isNotEmpty && (quran[0]['tilawah_done'] ?? false)),
          },
        ];

        final habitsItems = habits
            .take(3)
            .map(
              (h) => {
                'name': h['habit_name'] as String? ?? '',
                'completed': h['is_completed'] as bool? ?? false,
              },
            )
            .toList();

        final studyItems = study
            .take(3)
            .map(
              (s) => {
                'name': s['subject'] as String? ?? '',
                'completed': (s['hours_spent'] as num? ?? 0) > 0,
              },
            )
            .toList();

        return Scaffold(
          appBar: _CustomAppBar(
            title: fullName,
            showEditButton: true,
            studentId: widget.studentId,
          ),
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      // Avatar + Name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 140,
                              decoration: BoxDecoration(
                                color: avatarBg,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(60),
                                  topRight: Radius.circular(60),
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFADB8A6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            if (groupName != null || grade != null)
                              Text(
                                groupName ?? grade ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Daily Achievement Card
                      if (tracking != null)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyProgressScreen(
                                studentId: widget.studentId,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الإنجاز اليومي',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'اضغط للتفاصيل',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$progressPercent%',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: textSecondary,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'لا توجد بيانات لهذا اليوم',
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Section Cards Grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        children: [
                          _SectionCard(
                            title: 'عبادات',
                            icon: Icons.mosque_outlined,
                            items: ibadaatItems,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyProgressScreen(
                                  studentId: widget.studentId,
                                ),
                              ),
                            ),
                          ),
                          _SectionCard(
                            title: 'القرآن',
                            icon: Icons.menu_book_outlined,
                            items: quranItems,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyProgressScreen(
                                  studentId: widget.studentId,
                                ),
                              ),
                            ),
                          ),
                          _SectionCard(
                            title: 'عادات',
                            icon: Icons.self_improvement,
                            items: habitsItems,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyProgressScreen(
                                  studentId: widget.studentId,
                                ),
                              ),
                            ),
                          ),
                          _SectionCard(
                            title: 'دراسة',
                            icon: Icons.school_outlined,
                            items: studyItems,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DailyProgressScreen(
                                  studentId: widget.studentId,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
  const _CustomAppBar({
    required this.title,
    required this.showEditButton,
    this.studentId,
  });

  final String title;
  final bool showEditButton;
  final String? studentId;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (showEditButton && studentId != null)
          IconButton(
            icon: const Icon(Icons.edit, color: textPrimary),
            onPressed: () =>
                context.push(AddEditStudentScreen.editPath(studentId!)),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                final completed = item['completed'] as bool;
                final name = item['name'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        completed
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 16,
                        color: completed ? primary : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
