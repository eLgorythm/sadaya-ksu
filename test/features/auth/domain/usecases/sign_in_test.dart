import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/error/failure.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:sadaya/features/auth/domain/entities/user_entity.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_in.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const Failure(message: 'fallback'),
    );
  });

  setUp(() {
    repository = MockAuthRepository();
  });

  const user = UserEntity(
    id: 'u1',
    email: 'bendahara@ksucdp.or.id',
    fullName: 'Oruwasaton',
  );

  group('SignIn', () {
    test('mengembalikan error saat format email tidak valid', () async {
      final useCase = SignIn(repository);

      final result = await useCase(
        const SignInParams(email: 'bukan-email', password: 'rahasia'),
      );

      expect(result, isA<Err>());
      verifyNever(() => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('mengembalikan error saat password kurang dari 6 karakter', () async {
      final useCase = SignIn(repository);

      final result = await useCase(
        const SignInParams(email: 'bendahara@ksucdp.or.id', password: '12345'),
      );

      expect(result, isA<Err>());
      verifyNever(() => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('meneruskan ke repository saat input valid', () async {
      when(() => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Ok(user));

      final useCase = SignIn(repository);

      final result = await useCase(
        const SignInParams(email: 'bendahara@ksucdp.or.id', password: 'rahasia'),
      );

      expect(result, isA<Ok>());
      verify(() => repository.signIn(
            email: 'bendahara@ksucdp.or.id',
            password: 'rahasia',
          )).called(1);
    });
  });
}
