import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/tracking/domain/entities/daily_tracking.dart';
import 'package:students_app/features/tracking/presentation/providers/tracking_controller.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  static const String routeName = 'tracking';
  static const String routePath = '/tracking';

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final _studentIdController = TextEditingController();
  final _memorizationController = TextEditingController(text: '1');
  final _reviewController = TextEditingController(text: '2');
  final _studyMinutesController = TextEditingController(text: '30');
  int _prayerScore = 5;

  @override
  void dispose() {
    _studentIdController.dispose();
    _memorizationController.dispose();
    _reviewController.dispose();
    _studyMinutesController.dispose();
    super.dispose();
  }

  Future<void> _saveTracking() async {
    final tracking = DailyTracking(
      studentId: _studentIdController.text.trim(),
      date: DateTime.now(),
      prayerScore: _prayerScore,
      quranMemorizationPages: int.tryParse(_memorizationController.text) ?? 0,
      quranReviewPages: int.tryParse(_reviewController.text) ?? 0,
      studyMinutes: int.tryParse(_studyMinutesController.text) ?? 0,
    );

    await ref.read(trackingControllerProvider.notifier).save(tracking);

    if (!mounted) {
      return;
    }
    final saveState = ref.read(trackingControllerProvider);
    saveState.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ التقرير بنجاح')));
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التتبع اليومي / Daily Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(labelText: 'Student ID'),
          ),
          const SizedBox(height: 12),
          Text('تقييم الصلاة / Prayer Score: $_prayerScore'),
          Slider(
            value: _prayerScore.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: '$_prayerScore',
            onChanged: (value) => setState(() => _prayerScore = value.round()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memorizationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'صفحات الحفظ / Memorization Pages',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'صفحات المراجعة / Review Pages',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _studyMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'دقائق الدراسة / Study Minutes',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: trackingState.isLoading ? null : _saveTracking,
            child: trackingState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ / Save'),
          ),
        ],
      ),
    );
  }
}
