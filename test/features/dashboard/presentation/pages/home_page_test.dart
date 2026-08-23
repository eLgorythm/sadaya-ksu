import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/features/auth/domain/repositories/auth_repository.dart';
import 'package:sadaya/features/auth/domain/entities/user_entity.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_in.dart';
import 'package:sadaya/features/auth/domain/usecases/sign_out.dart';
import 'package:sadaya/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaya/features/auth/presentation/cubit/auth_state.dart';
import 'package:sadaya/features/dashboard/presentation/pages/home_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  testWidgets('menampilkan email pengguna yang login', (tester) async {
    final cubit = AuthCubit(SignIn(repository), SignOut(repository));
    cubit.emit(const AuthAuthenticated(
      UserEntity(id: 'u1', email: 'bendahara@ksucdp.or.id', fullName: 'Oru'),
    ));

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(home: HomePage()),
      ),
    );

    expect(find.text('bendahara@ksucdp.or.id'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
