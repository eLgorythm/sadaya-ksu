import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/error/failure.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/anggota/domain/entities/member_entity.dart';
import 'package:sadaya/features/anggota/domain/repositories/member_repository.dart';
import 'package:sadaya/features/anggota/domain/usecases/set_member_status.dart';
import 'package:sadaya/features/anggota/presentation/cubit/members_cubit.dart';

class MockMemberRepository extends Mock implements MemberRepository {}

class MockSetMemberStatus extends Mock implements SetMemberStatus {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MemberFilters());
    registerFallbackValue(
      const SetMemberStatusParams(id: '', status: 'active'),
    );
  });

  late MockMemberRepository repository;
  late MockSetMemberStatus setStatus;
  late MembersCubit cubit;

  final member = MemberEntity(
    id: 'id-1',
    memberNumber: 7,
    name: 'Budi Santoso',
    joinDate: DateTime(2026, 1, 15),
  );

  setUp(() {
    repository = MockMemberRepository();
    setStatus = MockSetMemberStatus();
    cubit = MembersCubit(repository, setStatus);
  });

  tearDown(() => cubit.close());

  group('load', () {
    blocTest<MembersCubit, MembersState>(
      'emits [inProgress, success] when repository succeeds',
      build: () {
        when(() => repository.getMembers(any()))
            .thenAnswer((_) async => Ok([member]));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<MembersLoadInProgress>(),
        isA<MembersLoadSuccess>()
            .having((s) => s.members.length, 'members length', 1)
            .having((s) => s.members.first.name, 'first name', 'Budi Santoso'),
      ],
    );

    blocTest<MembersCubit, MembersState>(
      'emits [inProgress, failure] when repository fails',
      build: () {
        when(() => repository.getMembers(any())).thenAnswer(
          (_) async =>
              const Err(Failure(message: 'Gagal memuat data anggota')),
        );
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<MembersLoadInProgress>(),
        isA<MembersFailure>()
            .having((s) => s.message, 'message', 'Gagal memuat data anggota'),
      ],
    );
  });

  group('searchChanged', () {
    blocTest<MembersCubit, MembersState>(
      'passes search term to repository',
      build: () {
        when(() => repository.getMembers(any()))
            .thenAnswer((_) async => const Ok(<MemberEntity>[]));
        return cubit;
      },
      act: (cubit) => cubit.searchChanged('budi'),
      verify: (_) {
        verify(() =>
                repository.getMembers(const MemberFilters(search: 'budi')))
            .called(1);
      },
    );
  });

  group('filterChanged', () {
    blocTest<MembersCubit, MembersState>(
      'passes status filter to repository',
      build: () {
        when(() => repository.getMembers(any()))
            .thenAnswer((_) async => const Ok(<MemberEntity>[]));
        return cubit;
      },
      act: (cubit) => cubit.filterChanged('active'),
      verify: (_) {
        verify(() => repository
                .getMembers(const MemberFilters(search: '', status: 'active')))
            .called(1);
      },
    );
  });

  group('changeStatus', () {
    blocTest<MembersCubit, MembersState>(
      'reloads list after status change succeeds',
      build: () {
        when(() => setStatus(any())).thenAnswer((_) async => const Ok(null));
        when(() => repository.getMembers(any()))
            .thenAnswer((_) async => const Ok(<MemberEntity>[]));
        return cubit;
      },
      act: (cubit) =>
          cubit.changeStatus(id: 'id-1', status: 'inactive'),
      verify: (_) {
        verify(() => setStatus(any(that: isA<SetMemberStatusParams>()
              .having((p) => p.status, 'status', 'inactive')
              .having((p) => p.id, 'id', 'id-1')))).called(1);
      },
      expect: () => [
        isA<MembersLoadInProgress>(),
        isA<MembersLoadSuccess>(),
      ],
    );

    blocTest<MembersCubit, MembersState>(
      'emits failure without reload when status change fails',
      build: () {
        when(() => setStatus(any())).thenAnswer(
          (_) async => const Err(Failure(message: 'Gagal mengubah status')),
        );
        return cubit;
      },
      act: (cubit) =>
          cubit.changeStatus(id: 'id-1', status: 'inactive'),
      verify: (_) {
        verifyNever(() => repository.getMembers(any()));
      },
      expect: () => [
        isA<MembersFailure>(),
      ],
    );
  });
}
