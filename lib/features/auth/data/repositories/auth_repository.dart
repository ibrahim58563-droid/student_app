import 'dart:async';

import 'package:students_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Represents application-specific authentication errors
sealed class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);

  @override
  String toString() => message;
}

final class InvalidCredentialsException extends AppAuthException {
  InvalidCredentialsException()
    : super('البريد الإلكتروني أو كلمة المرور غير صحيحة');
}

final class UserAlreadyExistsException extends AppAuthException {
  UserAlreadyExistsException() : super('هذا البريد الإلكتروني مسجل بالفعل');
}

final class NetworkException extends AppAuthException {
  NetworkException() : super('خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت');
}

final class UnknownAuthException extends AppAuthException {
  UnknownAuthException(super.message);
}

/// Auth repository - handles Supabase authentication and profile fetching
final class AuthService {
  const AuthService(this._supabaseClient);

  final supabase.SupabaseClient _supabaseClient;

  /// Sign in with email and password
  /// Throws [AppAuthException] on failure
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 15));

      final userId = response.user?.id;
      if (userId == null) {
        throw UnknownAuthException('فشل تسجيل الدخول');
      }

      return _fetchUserProfile(userId);
    } on AppAuthException {
      rethrow;
    } on TimeoutException {
      throw NetworkException();
    } on supabase.AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw InvalidCredentialsException();
      }
      throw UnknownAuthException(e.message);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('network') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('No address associated')) {
        throw NetworkException();
      }
      throw UnknownAuthException(errorStr);
    }
  }

  /// Sign up with email and password
  /// Throws [AppAuthException] on failure
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'admin',
  }) async {
    try {
      final response = await _supabaseClient.auth
          .signUp(
            email: email.trim(),
            password: password,
            data: {'full_name': fullName, 'role': role, 'avatar_index': 0},
          )
          .timeout(const Duration(seconds: 15));

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
    } on AppAuthException {
      rethrow;
    } on TimeoutException {
      throw NetworkException();
    } on supabase.AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw UserAlreadyExistsException();
      }
      throw UnknownAuthException(e.message);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('already registered')) {
        throw UserAlreadyExistsException();
      } else if (errorStr.contains('network') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('No address associated')) {
        throw NetworkException();
      }
      throw UnknownAuthException(errorStr);
    }
  }

  /// Get current authenticated user
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _supabaseClient.auth.currentSession;
      if (session == null || session.isExpired) {
        return null;
      }

      final userId = session.user.id;
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
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
          ); // ← maybeSingle بدل single عشان ميطلعش exception

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
    } on TimeoutException {
      throw NetworkException();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('network') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('No address associated')) {
        throw NetworkException();
      }
      throw UnknownAuthException('فشل في جلب بيانات المستخدم: $errorStr');
    }
  }

  UserRole _parseRole(String roleString) {
    return roleString == 'admin' ? UserRole.admin : UserRole.student;
  }
}
