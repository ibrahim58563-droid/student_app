import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/domain/repositories/auth_repository.dart';

final class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
