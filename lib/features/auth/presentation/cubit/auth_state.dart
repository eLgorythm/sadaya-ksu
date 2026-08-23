import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
