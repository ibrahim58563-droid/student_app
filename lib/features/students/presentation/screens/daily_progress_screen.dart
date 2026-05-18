
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primary = Color(0xFF1B5E20);
const Color background = Color(0xFFF0EDE6);
const Color cardBg = Color(0xFFEDE8DC);
const Color avatarBg = Color(0xFFCDD5C8);
const Color accent = Color(0xFFF59E0B);
const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF6B7280);

class DailyProgressScreen extends StatefulWidget {
  const DailyProgressScreen({required this.studentId, super.key});

  final String studentId;

  @override
  State<DailyProgressScreen> createState() => _DailyProgressScreenState();
}

class _DailyProgressScreenState extends State<DailyProgressScreen> {
  late Future<Map<String, dynamic>> progressDataFuture;

  @override
  void initState() {
    super.initState();
    progressDataFuture = _fetchProgressData();
  }

  Future<Map<String, dynamic>> _fetchProgressData() async {
    try {
      final supabase = Supabase.instance.client;

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

      if (tracking.isEmpty) {
        return {
          'tracking': null,
          'ibadaat': {},
          'quran': [],
          'habits': [],
          'study': [],
        };
      }

      final trackingData = tracking[0];
      final trackingId = trackingData['id'];

      // Fetch ibadaat data
      final ibadaatList = await supabase
          .from('ibadaat')
          .select()
          .eq('tracking_id', trackingId);

      // Fetch quran tracking data
      final quranList = await supabase
          .from('quran_tracking')
          .select()
          .eq('tracking_id', trackingId);

      // Fetch habits data
      final habitsList = await supabase
          .from('habits')
          .select()
          .eq('tracking_id', trackingId);

      // Fetch study sessions data
      final studyList = await supabase
          .from('study_sessions')
          .select()
          .eq('tracking_id', trackingId);

      return {
        'tracking': trackingData,
        'ibadaat': ibadaatList.isNotEmpty ? ibadaatList[0] : {},
        'quran': List<Map<String, dynamic>>.from(quranList),
        'habits': List<Map<String, dynamic>>.from(habitsList),
        'study': List<Map<String, dynamic>>.from(studyList),
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
      future: progressDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: const _CustomAppBar(title: 'Daily Progress'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: const _CustomAppBar(title: 'Daily Progress'),
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
                      progressDataFuture = _fetchProgressData();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final tracking = data['tracking'] as Map<String, dynamic>?;

        if (tracking == null) {
          return Scaffold(
            appBar: const _CustomAppBar(title: 'Daily Progress'),
            backgroundColor: background,
            body: SafeArea(
              child: Center(
                child: Text(
                  'لا توجد بيانات لهذا اليوم',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ),
          );
        }

        final ibadaat = data['ibadaat'] as Map<String, dynamic>;
        final quran = data['quran'] as List<Map<String, dynamic>>;
        final habits = data['habits'] as List<Map<String, dynamic>>;
        final study = data['study'] as List<Map<String, dynamic>>;

        final progressPercent = _calcProgress(ibadaat, quran, habits, study);

        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        return Scaffold(
          appBar: _CustomAppBar(title: 'Daily Progress', date: dateStr),
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      // Summary Card
                      Container(
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
                                  'SUMMARY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'الإنجاز اليومي',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ibadaat Section
                      _ProgressSection(
                        title: 'عبادات',
                        subtitle: 'IBADAAT',
                        items: _buildIbadaatItems(ibadaat),
                      ),
                      const SizedBox(height: 20),

                      // Quran Section
                      _ProgressSection(
                        title: 'القرآن',
                        subtitle: 'QURAN',
                        items: _buildQuranItems(quran),
                      ),
                      const SizedBox(height: 20),

                      // Habits Section
                      _ProgressSection(
                        title: 'عادات',
                        subtitle: 'HABITS',
                        items: _buildHabitsItems(habits),
                      ),
                      const SizedBox(height: 20),

                      // Study Section
                      _ProgressSection(
                        title: 'دراسة',
                        subtitle: 'STUDY',
                        items: _buildStudyItems(study),
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

  List<Map<String, dynamic>> _buildIbadaatItems(Map<String, dynamic> ibadaat) {
    return [
      {
        'name': 'الفجر',
        'completed': ibadaat['fajr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'name': 'الظهر',
        'completed': ibadaat['dhuhr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'name': 'العصر',
        'completed': ibadaat['asr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'name': 'المغرب',
        'completed': ibadaat['maghrib'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'name': 'العشاء',
        'completed': ibadaat['isha'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'name': 'أذكار الصباح',
        'completed': ibadaat['morning_adhkar'] ?? false,
        'icon': Icons.light_mode_outlined,
      },
      {
        'name': 'أذكار المساء',
        'completed': ibadaat['evening_adhkar'] ?? false,
        'icon': Icons.dark_mode_outlined,
      },
    ];
  }

  List<Map<String, dynamic>> _buildQuranItems(
    List<Map<String, dynamic>> quran,
  ) {
    if (quran.isEmpty) {
      return [
        {'name': 'حفظ', 'completed': false, 'icon': Icons.menu_book_outlined},
        {
          'name': 'مراجعة',
          'completed': false,
          'icon': Icons.menu_book_outlined,
        },
        {'name': 'تلاوة', 'completed': false, 'icon': Icons.menu_book_outlined},
      ];
    }

    final q = quran[0];
    return [
      {
        'name': 'حفظ',
        'completed': (q['hifz_pages'] ?? 0) > 0,
        'icon': Icons.menu_book_outlined,
      },
      {
        'name': 'مراجعة',
        'completed': (q['revision_pages'] ?? 0) > 0,
        'icon': Icons.menu_book_outlined,
      },
      {
        'name': 'تلاوة',
        'completed': q['tilawah_done'] ?? false,
        'icon': Icons.menu_book_outlined,
      },
    ];
  }

  List<Map<String, dynamic>> _buildHabitsItems(
    List<Map<String, dynamic>> habits,
  ) {
    return habits
        .map(
          (h) => {
            'name': h['habit_name'] as String? ?? '',
            'completed': h['is_completed'] as bool? ?? false,
            'icon': Icons.self_improvement,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _buildStudyItems(
    List<Map<String, dynamic>> study,
  ) {
    return study
        .map(
          (s) => {
            'name': s['subject'] as String? ?? '',
            'completed': (s['hours_spent'] as num? ?? 0) > 0,
            'icon': Icons.school_outlined,
          },
        )
        .toList();
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar({required this.title, this.date});

  final String title;
  final String? date;

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
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (date != null)
            Text(
              date!,
              style: const TextStyle(color: textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final completed = items.where((i) => i['completed'] as bool).length;
    final total = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$completed/$total COMPLETED',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: textSecondary, thickness: 0.5, height: 16),
        ...items.map((item) {
          final name = item['name'] as String;
          final completed = item['completed'] as bool;
          final icon = item['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: completed ? primary : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: TextStyle(
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: completed ? Colors.grey : textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Icon(
                  completed ? Icons.check_box : Icons.check_box_outline_blank,
                  color: completed ? primary : Colors.grey.shade300,
                  size: 20,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
