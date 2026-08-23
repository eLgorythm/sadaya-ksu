import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
