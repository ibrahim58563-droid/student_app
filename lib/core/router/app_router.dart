import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/core/constants/app_strings.dart';
import 'package:students_app/core/widgets/global_error_widget.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:students_app/features/auth/presentation/register_screen.dart';
import 'package:students_app/features/auth/presentation/screens/login_screen.dart';
import 'package:students_app/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_detail_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_list_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      final isAuthenticating =
          state.matchedLocation == LoginScreen.routePath ||
          state.matchedLocation == RegisterScreen.routePath;

      return authState.when(
        data: (user) {
          if (user != null && isAuthenticating) {
            return user.role == UserRole.admin
                ? '/admin/dashboard'
                : '/student/profile/${user.id}';
          }

          if (user == null && !isAuthenticating) {
            return LoginScreen.routePath;
          }

          return null;
        },
        loading: () {
          if (!isAuthenticating) {
            return LoginScreen.routePath;
          }
          return null;
        },
        error: (error, stackTrace) => LoginScreen.routePath,
      );
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/students',
        name: 'admin-students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/admin/students/:studentId',
        name: 'student-detail',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          return StudentDetailScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/student/profile/:studentId',
        name: 'student-profile',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          return StudentProfileScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/student/tracking/:studentId',
        name: 'student-tracking',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          return TrackingScreenWithStudentId(studentId: studentId);
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: GlobalErrorWidget.supabase(
          onRetry: () => context.go(LoginScreen.routePath),
        ),
      );
    },
  );
});

class TrackingScreenWithStudentId extends StatelessWidget {
  const TrackingScreenWithStudentId({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.trackingTitle)),
      body: Center(child: Text('Tracking for: $studentId')),
    );
  }
}
