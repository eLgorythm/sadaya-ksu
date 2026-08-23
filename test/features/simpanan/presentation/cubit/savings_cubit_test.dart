import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/error/failure.dart';
import 'package:sadaya/core/usecases/usecase.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/simpanan/domain/entities/saving_entities.dart';
import 'package:sadaya/features/simpanan/domain/usecases/get_savings.dart';
import 'package:sadaya/features/simpanan/presentation/cubit/savings_cubit.dart';

class MockGetMemberSavings extends Mock implements GetMemberSavings {}

class MockGetSavingsTypes extends Mock implements GetSavingsTypes {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  late MockGetMemberSavings getMemberSavings;
  late MockGetSavingsTypes getSavingsTypes;
  late SavingsCubit cubit;

  const types = [
    SavingsTypeEntity(
        id: 't-sp',
        code: 'SP',
        name: 'Simpanan Pokok',
        isWithdrawable: false),
    SavingsTypeEntity(
        id: 't-sms',
        code: 'SMS',
        name: 'Simpanan Mana Suka',
        isWithdrawable: true),
  ];

  setUp(() {
    getMemberSavings = MockGetMemberSavings();
    getSavingsTypes = MockGetSavingsTypes();
    when(() => getSavingsTypes(any()))
        .thenAnswer((_) async => const Ok(types));
    cubit = SavingsCubit(getMemberSavings, getSavingsTypes);
  });

  tearDown(() => cubit.close());

  blocTest<SavingsCubit, SavingsState>(
    'emits [inProgress, success] with balances and transactions',
    build: () {
      when(() => getMemberSavings('m1')).thenAnswer(
        (_) async => Ok(MemberSavingsSummary(
          balances: const {'SP': 100000, 'SMS': -0 + 50000},
          transactions: [
            SavingTransactionEntity(
              id: 'tx-1',
              memberId: 'm1',
              typeCode: 'SP',
              typeName: 'Simpanan Pokok',
              transactionType: 'deposit',
              amount: 100000,
              date: DateTime(2026, 8, 1),
            ),
          ],
        )),
      );
      return cubit;
    },
    act: (cubit) => cubit.load('m1'),
    expect: () => [
      isA<SavingsLoadInProgress>(),
      isA<SavingsLoadSuccess>()
          .having((s) => s.summary.balanceOf('SP'), 'SP balance', 100000)
          .having((s) => s.types.length, 'types count', 2),
    ],
  );

  blocTest<SavingsCubit, SavingsState>(
    'emits failure when summary load fails',
    build: () {
      when(() => getMemberSavings('m1')).thenAnswer(
        (_) async =>
            const Err(Failure(message: 'Gagal memuat data simpanan')),
      );
      return cubit;
    },
    act: (cubit) => cubit.load('m1'),
    expect: () => [
      isA<SavingsLoadInProgress>(),
      isA<SavingsFailure>()
          .having((s) => s.message, 'message', 'Gagal memuat data simpanan'),
    ],
  );
}
