import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents authentication errors with specific types
sealed class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

final class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException()
    : super('البريد الإلكتروني أو كلمة المرور غير صحيحة');
}

final class UserAlreadyExistsException extends AuthException {
  UserAlreadyExistsException() : super('هذا البريد الإلكتروني مسجل بالفعل');
}

final class NetworkException extends AuthException {
  NetworkException() : super('خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت');
}

final class UnknownAuthException extends AuthException {
  UnknownAuthException(super.message);
}

/// Auth repository - handles Supabase authentication and profile fetching
final class AuthService {
  const AuthService(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Sign in with email and password
  /// Throws [AuthException] on failure
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw UnknownAuthException('فشل تسجيل الدخول');
      }

      return _fetchUserProfile(userId);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        throw InvalidCredentialsException();
      } else if (e.toString().contains('network')) {
        throw NetworkException();
      }
      throw UnknownAuthException(e.toString());
    }
  }

  /// Sign up with email and password
  /// Throws [AuthException] on failure
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'admin',
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName, 'role': role, 'avatar_index': 0},
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw UnknownAuthException('فشل إنشاء الحساب');
      }

      // ← ضيف ده: احفظ الـ profile صراحةً
      await _supabaseClient.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'role': role,
        'avatar_index': 0,
      }, onConflict: 'id');

      return _fetchUserProfile(userId);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('already registered')) {
        throw UserAlreadyExistsException();
      } else if (e.toString().contains('network')) {
        throw NetworkException();
      }
      throw UnknownAuthException(e.toString());
    }
  }

  /// Get current authenticated user
  Future<AppUser?> getCurrentUser() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }
      return _fetchUserProfile(userId);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  /// Fetch user profile from profiles table
  /// Throws [UnknownAuthException] if profile not found
  Future<AppUser> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', userId)
          .maybeSingle(); // ← maybeSingle بدل single عشان ميطلعش exception

      if (response == null) {
        // الـ profile مش موجود — ارجع user بدون profile
        return AppUser(
          id: userId,
          name:
              _supabaseClient.auth.currentUser?.userMetadata?['full_name']
                  as String? ??
              'مستخدم',
          email: _supabaseClient.auth.currentUser?.email ?? '',
          role: UserRole.student,
        );
      }

      return AppUser(
        id: response['id'] as String,
        name: response['full_name'] as String? ?? 'مستخدم',
        email: _supabaseClient.auth.currentUser?.email ?? '',
        role: _parseRole(response['role'] as String? ?? 'student'),
      );
    } catch (e) {
      throw UnknownAuthException('فشل في جلب بيانات المستخدم');
    }
  }

  UserRole _parseRole(String roleString) {
    return roleString == 'admin' ? UserRole.admin : UserRole.student;
  }
}
