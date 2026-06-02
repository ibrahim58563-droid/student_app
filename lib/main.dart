import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/core/providers/connectivity_provider.dart';
import 'package:students_app/core/router/app_router.dart';
import 'package:students_app/core/theme/app_theme.dart';
import 'package:students_app/core/widgets/no_internet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oztdthttfxbkldxnstbe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96dGR0aHR0Znhia2xkeG5zdGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MTI0MjksImV4cCI6MjA5Mzk4ODQyOX0.FNo-yILaoKIfFCVTwcuMt9mHTNw6xwrlObkcLNZMLWo',
  );

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    final router = ref.watch(appRouterProvider);

    final isDisconnected = connectivityState.maybeWhen(
      data: (isConnected) => !isConnected,
      orElse: () => false,
    );

    return MaterialApp.router(
      title: 'متابعة الطلاب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: isDisconnected
              ? NoInternetScreen(
                  onRetry: () => ref.invalidate(connectivityProvider),
                )
              : (child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
