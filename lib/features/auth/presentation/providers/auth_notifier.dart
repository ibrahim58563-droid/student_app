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
  late AuthRepository _authRepository;

  @override
  Future<AppUser?> build() async {
    _authRepository = AuthRepository(Supabase.instance.client);
    return _authRepository.getCurrentUser();
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authRepository.signInWithEmail(email: email, password: password),
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      ),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}
