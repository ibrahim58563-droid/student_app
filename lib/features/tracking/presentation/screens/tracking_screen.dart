import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// This screen is deprecated - tracking is now done via StudentProfileScreen
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  static const String routeName = 'tracking';
  static const String routePath = '/tracking';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة يومية')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'المتابعة اليومية متاحة من ملف الطالب',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('الرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
