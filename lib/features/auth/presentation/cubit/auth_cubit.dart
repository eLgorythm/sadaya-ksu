import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._signIn, this._signOut) : super(const AuthInitial());

  final SignIn _signIn;
  final SignOut _signOut;

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await _signIn(
      SignInParams(email: email, password: password),
    );
    switch (result) {
      case final Ok<UserEntity> ok:
        emit(AuthAuthenticated(ok.value));
      case final Err err:
        emit(AuthError(err.failure.message));
        emit(const AuthInitial());
    }
  }

  Future<void> signOut() async {
    await _signOut(const NoParams());
    emit(const AuthUnauthenticated());
  }

  void reset() => emit(const AuthInitial());
}
