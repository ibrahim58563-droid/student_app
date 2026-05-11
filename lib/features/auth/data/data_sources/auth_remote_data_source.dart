import 'package:supabase_flutter/supabase_flutter.dart';

final class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id ?? _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('تعذر تحميل بيانات المستخدم بعد تسجيل الدخول');
    }

    final profile = await _client
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', userId)
        .single();

    return {...profile.cast<String, dynamic>(), 'email': email};
  }
}
