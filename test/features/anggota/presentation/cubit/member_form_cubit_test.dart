import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/error/failure.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/anggota/domain/entities/member_entity.dart';
import 'package:sadaya/features/anggota/domain/usecases/create_member.dart';
import 'package:sadaya/features/anggota/domain/usecases/update_member.dart';
import 'package:sadaya/features/anggota/presentation/cubit/member_form_cubit.dart';

class MockCreateMember extends Mock implements CreateMember {}

class MockUpdateMember extends Mock implements UpdateMember {}

void main() {
  setUpAll(() {
    registerFallbackValue(CreateMemberParams(name: '', joinDate: DateTime(2026)));
    registerFallbackValue(UpdateMemberParams(
      id: '',
      memberNumber: 0,
      name: '',
      joinDate: DateTime(2026),
    ));
  });

  late MockCreateMember createMember;
  late MockUpdateMember updateMember;
  late MemberFormCubit cubit;

  final saved = MemberEntity(
    id: 'id-1',
    memberNumber: 8,
    name: 'Siti Aminah',
    joinDate: DateTime(2026, 2, 1),
  );

  setUp(() {
    createMember = MockCreateMember();
    updateMember = MockUpdateMember();
    cubit = MemberFormCubit(createMember, updateMember);
  });

  tearDown(() => cubit.close());

  group('save (create)', () {
    blocTest<MemberFormCubit, MemberFormState>(
      'emits [saving, success] when use case succeeds',
      build: () {
        when(() => createMember(any()))
            .thenAnswer((_) async => Ok(saved));
        return cubit;
      },
      act: (cubit) => cubit.save(
        memberNumber: 0,
        name: 'Siti Aminah',
        joinDate: DateTime(2026, 2, 1),
      ),
      expect: () => [
        isA<MemberFormSaving>(),
        isA<MemberFormSuccess>()
            .having((s) => s.isEdit, 'isEdit', false)
            .having((s) => s.member.name, 'name', 'Siti Aminah'),
      ],
    );

    blocTest<MemberFormCubit, MemberFormState>(
      'emits [saving, failure] when use case fails',
      build: () {
        when(() => createMember(any())).thenAnswer(
          (_) async => const Err(Failure(message: 'Gagal menyimpan anggota')),
        );
        return cubit;
      },
      act: (cubit) => cubit.save(
        memberNumber: 0,
        name: 'Siti Aminah',
        joinDate: DateTime(2026, 2, 1),
      ),
      expect: () => [
        isA<MemberFormSaving>(),
        isA<MemberFormFailure>(),
      ],
    );
  });

  group('save (edit)', () {
    blocTest<MemberFormCubit, MemberFormState>(
      'routes to update use case when id provided and reports isEdit true',
      build: () {
        when(() => updateMember(any()))
            .thenAnswer((_) async => Ok(saved));
        return cubit;
      },
      act: (cubit) => cubit.save(
        id: 'id-1',
        memberNumber: 8,
        name: 'Siti Aminah',
        joinDate: DateTime(2026, 2, 1),
      ),
      verify: (_) {
        verifyNever(() => createMember(any()));
      },
      expect: () => [
        isA<MemberFormSaving>(),
        isA<MemberFormSuccess>().having((s) => s.isEdit, 'isEdit', true),
      ],
    );
  });

  test('reset returns to initial state', () {
    cubit.emit(const MemberFormFailure('err'));
    cubit.reset();
    expect(cubit.state, const MemberFormInitial());
  });
}
