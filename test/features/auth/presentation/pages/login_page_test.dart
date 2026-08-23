import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_in.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_out.dart';
import 'package:sadaya/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaya/features/auth/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  Widget buildWidget() => BlocProvider<AuthCubit>.value(
        value: AuthCubit(SignIn(repository), SignOut(repository)),
        child: const MaterialApp(home: LoginPage()),
      );

  testWidgets('menampilkan judul, moto, dan form login', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Sadaya'), findsOneWidget);
    expect(find.text('KSU Cahaya Dhamma Phala'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('menampilkan pesan validasi saat form kosong', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
    verifyNever(() => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });
}
