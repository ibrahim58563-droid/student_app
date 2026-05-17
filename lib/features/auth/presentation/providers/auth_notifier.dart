import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/auth/data/repositories/auth_repository.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth state provider
final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(
  AuthNotifier.new,
);

/// Auth notifier - manages authentication state
final class AuthNotifier extends AsyncNotifier<AppUser?> {
  late AuthService _authService;

  @override
  Future<AppUser?> build() async {
    _authService = AuthService(Supabase.instance.client);
    return _authService.getCurrentUser();
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithEmail(email: email, password: password),
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      ),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}
