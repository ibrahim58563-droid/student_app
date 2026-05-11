import 'package:students_app/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});
}
