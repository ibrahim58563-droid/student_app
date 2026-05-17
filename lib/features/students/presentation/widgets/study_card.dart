import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/constants/app_colors.dart';
import 'package:students_app/features/students/domain/models/tracking_data.dart';
import 'package:students_app/features/students/presentation/providers/student_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyCard extends ConsumerStatefulWidget {
  const StudyCard({
    required this.tracking,
    required this.studentId,
    required this.isAdmin,
    super.key,
  });

  final StudentTrackingData tracking;
  final String studentId;
  final bool isAdmin;

  @override
  ConsumerState<StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends ConsumerState<StudyCard>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _tabIndex = 0;

  List<StudySessionData> get sessions => widget.tracking.studySessions;

  @override
  void didUpdateWidget(StudyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracking.studySessions.length != sessions.length) {
      _initTabController();
    }
  }

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  void _initTabController() {
    _tabController?.dispose();
    if (sessions.isNotEmpty) {
      _tabController = TabController(
        length: sessions.length,
        vsync: this,
        initialIndex: _tabIndex.clamp(0, sessions.length - 1),
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() => _tabIndex = _tabController!.index);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    final subjectName = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة مادة دراسية'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثال: رياضيات، لغة عربية...',
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

    if (subjectName == null || subjectName.isEmpty) return;
    if (widget.tracking.trackingId.isEmpty) return;

    try {
      await Supabase.instance.client.from('study_sessions').insert({
        'tracking_id': widget.tracking.trackingId,
        'subject': subjectName,
        'hours_spent': 0,
        'task_description': '',
      });
      ref.invalidate(studentTrackingProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _removeSubject(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('study_sessions')
          .delete()
          .eq('id', sessionId);
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
                    '🎓 الدراسة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      onPressed: _addSubject,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      tooltip: 'إضافة مادة',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Empty state
            if (sessions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    widget.isAdmin
                        ? 'اضغط + لإضافة مواد دراسية'
                        : 'لم تضف مواد دراسية بعد',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else ...[
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: Theme.of(context).textTheme.labelSmall,
                tabs: sessions
                    .map(
                      (s) => Tab(
                        child: Row(
                          children: [
                            Text(s.subject),
                            if (widget.isAdmin) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  // get session id from Supabase
                                  _removeSubjectByName(s.subject);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red.shade300,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Tab content
              SizedBox(
                height: 180,
                child: TabBarView(
                  controller: _tabController,
                  children: sessions.map((session) {
                    return _SessionContent(
                      session: session,
                      studentId: widget.studentId,
                      isLoading: isLoading,
                      onUpdate: (hours) {
                        ref
                            .read(
                              studentTrackingProvider(
                                widget.studentId,
                              ).notifier,
                            )
                            .updateStudySession(
                              session.subject,
                              hours,
                              session.dailyGoal,
                            );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeSubjectByName(String subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المادة'),
          content: Text('هل تريد حذف "$subject"؟'),
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
    if (widget.tracking.trackingId.isEmpty) return;

    try {
      await Supabase.instance.client
          .from('study_sessions')
          .delete()
          .eq('tracking_id', widget.tracking.trackingId)
          .eq('subject', subject);
      ref.invalidate(studentTrackingProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}

class _SessionContent extends StatelessWidget {
  const _SessionContent({
    required this.session,
    required this.studentId,
    required this.isLoading,
    required this.onUpdate,
  });

  final StudySessionData session;
  final String studentId;
  final bool isLoading;
  final void Function(double hours) onUpdate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hours vs goal
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الوقت المستغرق',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${session.hoursSpent.toStringAsFixed(1)}/${session.dailyGoal.toStringAsFixed(1)} ساعات',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                session.progress >= 1.0
                    ? AppColors.accentGreen
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Slider
          Text(
            'اضبط الساعات',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          Slider(
            value: session.hoursSpent.clamp(0.0, 8.0),
            min: 0,
            max: 8,
            divisions: 16,
            label: session.hoursSpent.toStringAsFixed(1),
            onChanged: isLoading ? null : onUpdate,
          ),
        ],
      ),
    );
  }
}
