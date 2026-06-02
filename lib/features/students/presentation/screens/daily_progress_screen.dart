import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primary = Color(0xFF1B5E20);
const Color background = Color(0xFFF0EDE6);
const Color cardBg = Color(0xFFEDE8DC);
const Color avatarBg = Color(0xFFCDD5C8);
const Color accent = Color(0xFFF59E0B);
const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF6B7280);

enum DailyProgressSection { ibadaat, quran, habits, study }

class DailyProgressScreen extends StatefulWidget {
  const DailyProgressScreen({
    required this.studentId,
    this.initialSection,
    super.key,
  });

  final String studentId;
  final DailyProgressSection? initialSection;

  @override
  State<DailyProgressScreen> createState() => _DailyProgressScreenState();
}

class _DailyProgressScreenState extends State<DailyProgressScreen> {
  late Future<Map<String, dynamic>> progressDataFuture;

  String _friendlyErrorMessage(Object error) {
    final msg = error.toString();

    if (msg.contains('row-level security') ||
        msg.contains('42501') ||
        msg.contains('Forbidden')) {
      return 'ليس لديك صلاحية لإضافة أو تعديل المتابعة لهذا الطالب. راجع RLS في Supabase.';
    }

    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من الشبكة وحاول مجددًا.';
    }

    return 'حدث خطأ أثناء حفظ البيانات. حاول مرة أخرى.';
  }

  void _showErrorSnack(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_friendlyErrorMessage(error))));
  }

  String get _today => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    progressDataFuture = _fetchProgressData();
  }

  Future<String?> _getTrackingId() async {
    final supabase = Supabase.instance.client;

    final existingTracking = await supabase
        .from('daily_tracking')
        .select('id')
        .eq('student_id', widget.studentId)
        .eq('tracking_date', _today)
        .maybeSingle();

    return existingTracking?['id'] as String?;
  }

  Future<String> _ensureTracking() async {
    final supabase = Supabase.instance.client;

    // Try to get existing tracking
    final existingId = await _getTrackingId();
    if (existingId != null) {
      return existingId;
    }

    // Create new tracking if doesn't exist
    try {
      final newTracking = await supabase
          .from('daily_tracking')
          .insert({'student_id': widget.studentId, 'tracking_date': _today})
          .select('id')
          .single();

      return newTracking['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _ensureIbadaatRecord(String trackingId) async {
    final supabase = Supabase.instance.client;

    final existingIbadaat = await supabase
        .from('ibadaat')
        .select('id')
        .eq('tracking_id', trackingId)
        .maybeSingle();

    if (existingIbadaat != null) {
      return;
    }

    await supabase.from('ibadaat').insert({
      'tracking_id': trackingId,
      'fajr': false,
      'dhuhr': false,
      'asr': false,
      'maghrib': false,
      'isha': false,
      'morning_adhkar': false,
      'evening_adhkar': false,
    });
  }

  Future<Map<String, dynamic>> _fetchProgressData() async {
    try {
      final supabase = Supabase.instance.client;

      final trackingId = await _getTrackingId();

      if (trackingId == null) {
        return {
          'tracking': null,
          'ibadaat': {},
          'quran': [],
          'habits': [],
          'study': [],
        };
      }

      final trackingData = await supabase
          .from('daily_tracking')
          .select()
          .eq('id', trackingId)
          .single();

      await _ensureIbadaatRecord(trackingId);

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
      final completed = quran.where((q) {
        final hifzPages = (q['hifz_pages'] ?? 0) as int;
        final revisionPages = (q['revision_pages'] ?? 0) as int;
        final tilawahDone = q['tilawah_done'] as bool? ?? false;
        return hifzPages > 0 || revisionPages > 0 || tilawahDone;
      }).length;
      quranScore = completed / quran.length;
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
            appBar: const _CustomAppBar(title: 'إدارة المهام اليومية'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: const _CustomAppBar(title: 'إدارة المهام اليومية'),
            backgroundColor: background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تأكد من:\n• اتصالك بالإنترنت\n• اختيارك للطالب الصحيح\n• وجود بيانات متابعة لهذا اليوم',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {
                          progressDataFuture = _fetchProgressData();
                        }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('حاول مجدداً'),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('العودة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final ibadaatRaw = data['ibadaat'];
        final ibadaat = ibadaatRaw is Map
            ? Map<String, dynamic>.from(ibadaatRaw)
            : <String, dynamic>{};
        final quran = (data['quran'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final habits = (data['habits'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final study = (data['study'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        final progressPercent = _calcProgress(ibadaat, quran, habits, study);
        final dateStr = _today;

        return Scaffold(
          appBar: _CustomAppBar(title: 'إدارة المهام اليومية', date: dateStr),
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      // Summary Card with Progress Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$progressPercent%',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressPercent / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressPercent >= 70
                                      ? primary
                                      : progressPercent >= 40
                                      ? accent
                                      : Colors.red.shade300,
                                ),
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
                        onToggle: (item) async {
                          final field = item['field'] as String;
                          try {
                            final trackingId = await _ensureTracking();
                            await _ensureIbadaatRecord(trackingId);
                            final currentIbadaat = await Supabase
                                .instance
                                .client
                                .from('ibadaat')
                                .select()
                                .eq('tracking_id', trackingId)
                                .single();
                            final current = currentIbadaat[field] ?? false;
                            await Supabase.instance.client
                                .from('ibadaat')
                                .update({field: !current})
                                .eq('id', currentIbadaat['id']);
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                          setState(() {
                            progressDataFuture = _fetchProgressData();
                          });
                        },
                        onAdd: () async {
                          try {
                            final tId = await _ensureTracking();
                            await _ensureIbadaatRecord(tId);
                            setState(() {
                              progressDataFuture = _fetchProgressData();
                            });
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Quran Section
                      _ProgressSection(
                        title: 'القرآن',
                        subtitle: 'QURAN',
                        items: _buildQuranItems(quran),
                        onToggle: (item) async {
                          final id = item['id'] as String;
                          final current = item['completed'] as bool;
                          try {
                            await Supabase.instance.client
                                .from('quran_tracking')
                                .update({'tilawah_done': !current})
                                .eq('id', id);
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                          setState(() {
                            progressDataFuture = _fetchProgressData();
                          });
                        },
                        onAdd: () async {
                          try {
                            final tId = await _ensureTracking();
                            await _addQuranTask(tId);
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Habits Section
                      _ProgressSection(
                        title: 'عادات',
                        subtitle: 'HABITS',
                        items: _buildHabitsItems(habits),
                        onToggle: (item) async {
                          try {
                            final id = item['id'];
                            final current = item['completed'] as bool;
                            await Supabase.instance.client
                                .from('habits')
                                .update({'is_completed': !current})
                                .eq('id', id);
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                          setState(() {
                            progressDataFuture = _fetchProgressData();
                          });
                        },
                        onAdd: () async {
                          final nameController = TextEditingController();
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('أضف عادة جديدة'),
                              content: TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'اسم العادة',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('إضافة'),
                                ),
                              ],
                            ),
                          );
                          if (result == true &&
                              nameController.text.trim().isNotEmpty) {
                            try {
                              final tId = await _ensureTracking();
                              await Supabase.instance.client
                                  .from('habits')
                                  .insert({
                                    'tracking_id': tId,
                                    'habit_name': nameController.text.trim(),
                                    'is_completed': false,
                                  });
                            } catch (e) {
                              _showErrorSnack(e);
                            }
                            setState(() {
                              progressDataFuture = _fetchProgressData();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Study Section
                      _ProgressSection(
                        title: 'دراسة',
                        subtitle: 'STUDY',
                        items: _buildStudyItems(study),
                        onToggle: (item) async {
                          try {
                            final id = item['id'];
                            final current = item['completed'] as bool;
                            await Supabase.instance.client
                                .from('study_sessions')
                                .update({'hours_spent': current ? 0 : 1})
                                .eq('id', id);
                          } catch (e) {
                            _showErrorSnack(e);
                          }
                          setState(() {
                            progressDataFuture = _fetchProgressData();
                          });
                        },
                        onAdd: () async {
                          final nameController = TextEditingController();
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('أضف جلسة دراسة'),
                              content: TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'المادة',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('إضافة'),
                                ),
                              ],
                            ),
                          );
                          if (result == true &&
                              nameController.text.trim().isNotEmpty) {
                            try {
                              final tId = await _ensureTracking();
                              await Supabase.instance.client
                                  .from('study_sessions')
                                  .insert({
                                    'tracking_id': tId,
                                    'subject': nameController.text.trim(),
                                    'hours_spent': 0,
                                  });
                            } catch (e) {
                              _showErrorSnack(e);
                            }
                            setState(() {
                              progressDataFuture = _fetchProgressData();
                            });
                          }
                        },
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
    final id = ibadaat['id'] as String?;

    // Return items even if id is null - they just won't be editable until tracking is created
    return [
      {
        'id': id,
        'field': 'fajr',
        'name': 'الفجر',
        'completed': ibadaat['fajr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'id': id,
        'field': 'dhuhr',
        'name': 'الظهر',
        'completed': ibadaat['dhuhr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'id': id,
        'field': 'asr',
        'name': 'العصر',
        'completed': ibadaat['asr'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'id': id,
        'field': 'maghrib',
        'name': 'المغرب',
        'completed': ibadaat['maghrib'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'id': id,
        'field': 'isha',
        'name': 'العشاء',
        'completed': ibadaat['isha'] ?? false,
        'icon': Icons.mosque_outlined,
      },
      {
        'id': id,
        'field': 'morning_adhkar',
        'name': 'أذكار الصباح',
        'completed': ibadaat['morning_adhkar'] ?? false,
        'icon': Icons.light_mode_outlined,
      },
      {
        'id': id,
        'field': 'evening_adhkar',
        'name': 'أذكار المساء',
        'completed': ibadaat['evening_adhkar'] ?? false,
        'icon': Icons.dark_mode_outlined,
      },
    ];
  }

  List<Map<String, dynamic>> _buildQuranItems(
    List<Map<String, dynamic>> quran,
  ) {
    return quran
        .map(
          (q) => {
            'id': q['id'],
            'name': (q['current_surah'] as String? ?? '').trim().isEmpty
                ? 'مهمة قرآن'
                : q['current_surah'] as String,
            'completed': q['tilawah_done'] as bool? ?? false,
            'icon': Icons.menu_book_outlined,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _buildHabitsItems(
    List<Map<String, dynamic>> habits,
  ) {
    return habits
        .map(
          (h) => {
            'id': h['id'],
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
            'id': s['id'],
            'name': s['subject'] as String? ?? '',
            'completed': (s['hours_spent'] as num? ?? 0) > 0,
            'icon': Icons.school_outlined,
          },
        )
        .toList();
  }

  Future<void> _addQuranTask(String trackingId) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة مهمة قرآن'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثال: سورة الكهف، مراجعة جزء عم... ',
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

    if (title == null || title.isEmpty) return;

    try {
      await Supabase.instance.client.from('quran_tracking').insert({
        'tracking_id': trackingId,
        'current_surah': title,
        'hifz_pages': 0,
        'revision_pages': 0,
        'tilawah_done': false,
      });
      if (mounted) {
        setState(() {
          progressDataFuture = _fetchProgressData();
        });
      }
    } catch (e) {
      _showErrorSnack(e);
    }
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
        onPressed: () {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (context.mounted) Navigator.pop(context);
          });
        },
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
    this.onToggle,
    this.onAdd,
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(Map<String, dynamic> item)? onToggle;
  final Future<void> Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((i) => i['completed'] as bool).length;
    final total = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onAdd != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: FloatingActionButton.small(
                          onPressed: () => onAdd?.call(),
                          backgroundColor: Colors.white,
                          elevation: 0,
                          child: const Icon(
                            Icons.add,
                            color: primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    '$completed/$total COMPLETED',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Items list
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'لا توجد عناصر بعد',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final name = item['name'] as String;
                final isCompleted = item['completed'] as bool;
                final icon = item['icon'] as IconData;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: onToggle != null ? () => onToggle!(item) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 20,
                                    color: isCompleted
                                        ? primary
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isCompleted
                                            ? Colors.grey.shade500
                                            : textPrimary,
                                        fontSize: 14,
                                        fontWeight: isCompleted
                                            ? FontWeight.w400
                                            : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: onToggle != null
                                  ? () => onToggle!(item)
                                  : null,
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isCompleted
                                    ? primary
                                    : Colors.grey.shade300,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        color: Colors.grey.shade200,
                        thickness: 0.5,
                        height: 0,
                        indent: 44,
                        endIndent: 12,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
