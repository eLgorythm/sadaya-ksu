import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      return await _client
          .from('users')
          .select('full_name, jabatan')
          .eq('id', userId)
          .single();
    } catch (_) {
      return null;
    }
  }
}
