import 'package:students_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:students_app/features/auth/data/models/app_user_model.dart';
import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:students_app/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );
    return AppUserModel.fromMap(result).toEntity();
  }
}
