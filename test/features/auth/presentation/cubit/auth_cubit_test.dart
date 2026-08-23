import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/error/failure.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:sadaya/features/auth/domain/entities/user_entity.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_in.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_out.dart';
import 'package:sadaya/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaya/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  const user = UserEntity(
    id: 'u1',
    email: 'bendahara@ksucdp.or.id',
    fullName: 'Oruwasaton',
  );

  AuthCubit buildCubit() => AuthCubit(SignIn(repository), SignOut(repository));

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'emit [Loading, Authenticated] saat login berhasil',
      build: () {
        when(() => repository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Ok(user));
        return buildCubit();
      },
      act: (cubit) => cubit.signIn(
        email: 'bendahara@ksucdp.or.id',
        password: 'rahasia',
      ),
      expect: () => const [AuthLoading(), AuthAuthenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emit [Loading, Error, Initial] saat kredensial salah',
      build: () {
        when(() => repository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer(
          (_) async =>
              const Err(Failure(message: 'Email atau password salah')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.signIn(
        email: 'bendahara@ksucdp.or.id',
        password: 'salahbanget',
      ),
      expect: () => const [
        AuthLoading(),
        AuthError('Email atau password salah'),
        AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'tidak memanggil repository saat email tidak valid',
      build: () {
        when(() => repository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Ok(user));
        return buildCubit();
      },
      act: (cubit) => cubit.signIn(email: 'tidak-valid', password: 'rahasia'),
      expect: () => const [
        AuthLoading(),
        AuthError('Format email tidak valid'),
        AuthInitial(),
      ],
      verify: (_) => verifyNever(() => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )),
    );
  });
}
