import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:students_app/features/auth/presentation/register_screen.dart';
import 'package:students_app/features/auth/presentation/screens/login_screen.dart';
import 'package:students_app/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:students_app/features/students/presentation/screens/add_edit_student_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_detail_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_profile_screen.dart';
import 'package:students_app/features/students/presentation/screens/student_registry_screen.dart';

// Helper: converts Riverpod state into a Listenable for GoRouter
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: LoginScreen.routePath,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue = ref.read(authProvider);

      // If state is still loading, don't redirect yet
      if (authValue.isLoading) return null;

      final user = authValue.value;
      final isAuthenticating =
          state.matchedLocation == LoginScreen.routePath ||
          state.matchedLocation == RegisterScreen.routePath;

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
        builder: (context, state) => const StudentRegistryScreen(),
        routes: [
          // ✅ add لازم تيجي الأول
          GoRoute(
            path: 'add',
            name: 'add-student',
            builder: (context, state) => const AddEditStudentScreen(),
          ),
          GoRoute(
            path: ':studentId',
            name: 'student-detail',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId'] ?? '';
              return StudentDetailScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-student',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId'] ?? '';
                  return AddEditStudentScreen(studentId: studentId);
                },
              ),
            ],
          ),
        ],
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
        redirect: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          return '/student/profile/$studentId';
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error.toString(), // ← اعرض الـ error الحقيقي
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${state.uri}', // ← اعرض الـ URL
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    },
  );
});
