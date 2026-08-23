import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signIn(email, password);
      final user = response.user;
      if (user == null) {
        return const Err(Failure(message: 'Login gagal, silakan coba lagi'));
      }
      final profile = await _dataSource.fetchProfile(user.id);
      return Ok(UserModel.fromSupabase(user, profile));
    } on AuthException catch (e) {
      return Err(Failure(message: _mapAuthError(e), code: '${e.statusCode}'));
    } catch (_) {
      return const Err(
        Failure(message: 'Terjadi kesalahan. Periksa koneksi internet Anda'),
      );
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi';
    }
    if (message.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat lagi';
    }
    return e.message;
  }
}
