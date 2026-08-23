import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/simpanan/domain/entities/saving_entities.dart';
import 'package:sadaya/features/simpanan/domain/repositories/savings_repository.dart';
import 'package:sadaya/features/simpanan/domain/usecases/create_saving_transaction.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SavingsTypeEntity(
      id: 'fallback',
      code: 'SP',
      name: 'Simpanan Pokok',
      isWithdrawable: false,
    ));
    registerFallbackValue(const CreateSavingTransactionParams(
      memberId: '',
      type: SavingsTypeEntity(
        id: 'fallback',
        code: 'SP',
        name: 'Simpanan Pokok',
        isWithdrawable: false,
      ),
      transactionType: 'deposit',
      amount: 0,
    ));
  });

  late MockSavingsRepository repository;
  late CreateSavingTransaction useCase;

  const sp = SavingsTypeEntity(
      id: 't-sp',
      code: 'SP',
      name: 'Simpanan Pokok',
      isWithdrawable: false);
  const sms = SavingsTypeEntity(
      id: 't-sms', code: 'SMS', name: 'Simpanan Mana Suka', isWithdrawable: true);
  const swk = SavingsTypeEntity(
      id: 't-swk',
      code: 'SWK',
      name: 'Simpanan Wajib Kredit',
      isWithdrawable: false);

  setUp(() {
    repository = MockSavingsRepository();
    useCase = CreateSavingTransaction(repository);
  });

  test('deposit on normal type delegates to repository', () async {
    when(() => repository.createTransaction(
          memberId: any(named: 'memberId'),
          type: any(named: 'type'),
          transactionType: any(named: 'transactionType'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
        )).thenAnswer((_) async => Ok(_fakeTx()));

    final result = await useCase(CreateSavingTransactionParams(
      memberId: 'm1',
      type: sp,
      transactionType: 'deposit',
      amount: 100000,
    ));

    expect(result, isA<Ok<SavingTransactionEntity>>());
  });

  test('withdrawal blocked on non-withdrawable type', () async {
    final result = await useCase(CreateSavingTransactionParams(
      memberId: 'm1',
      type: sp,
      transactionType: 'withdrawal',
      amount: 50000,
    ));

    final message = switch (result) {
      Err(:final failure) => failure.message,
      Ok() => null,
    };
    expect(message, contains('tidak dapat ditarik'));
    verifyNever(() => repository.createTransaction(
          memberId: any(named: 'memberId'),
          type: any(named: 'type'),
          transactionType: any(named: 'transactionType'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
        ));
  });

  test('SWK rejected because system-managed', () async {
    final result = await useCase(CreateSavingTransactionParams(
      memberId: 'm1',
      type: swk,
      transactionType: 'deposit',
      amount: 10000,
    ));

    final failure = switch (result) {
      Err(:final failure) => failure,
      Ok() => null,
    };
    expect(failure, isNotNull);
    expect(failure!.message, contains('otomatis'));
  });

  test('zero amount rejected', () async {
    final result = await useCase(CreateSavingTransactionParams(
      memberId: 'm1',
      type: sms,
      transactionType: 'deposit',
      amount: 0,
    ));

    expect(result, isA<Err<SavingTransactionEntity>>());
  });
}

SavingTransactionEntity _fakeTx() => SavingTransactionEntity(
      id: 'tx-1',
      memberId: 'm1',
      typeCode: 'SP',
      typeName: 'Simpanan Pokok',
      transactionType: 'deposit',
      amount: 100000,
      date: DateTime(2026, 8, 23),
    );
