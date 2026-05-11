import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:students_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

final class AuthController extends AsyncNotifier<AppUser?> {
  late final SignInUseCase _signInUseCase;

  @override
  Future<AppUser?> build() async {
    final remoteDataSource = AuthRemoteDataSource(Supabase.instance.client);
    final repository = AuthRepositoryImpl(remoteDataSource);
    _signInUseCase = SignInUseCase(repository);
    return null;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _signInUseCase(email: email, password: password),
    );
  }
}
