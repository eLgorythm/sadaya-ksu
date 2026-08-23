import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

@lazySingleton
class SignIn implements UseCase<UserEntity, SignInParams> {
  SignIn(this._repository);

  final AuthRepository _repository;

  static final RegExp _emailRegex = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$',
  );

  @override
  Future<Result<UserEntity>> call(SignInParams params) async {
    final email = params.email.trim();
    if (!_emailRegex.hasMatch(email)) {
      return const Err(Failure(message: 'Format email tidak valid'));
    }
    if (params.password.length < 6) {
      return const Err(Failure(message: 'Password minimal 6 karakter'));
    }
    return _repository.signIn(email: email, password: params.password);
  }
}
