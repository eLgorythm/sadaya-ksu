import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadaya/core/utils/result.dart';
import 'package:sadaya/features/pinjaman/domain/entities/loan_entities.dart';
import 'package:sadaya/features/pinjaman/domain/repositories/loan_repository.dart';
import 'package:sadaya/features/pinjaman/domain/usecases/create_loan.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

LoanEntity _fakeLoan() => LoanEntity(
      id: 'l-1',
      loanNumber: 12,
      principalAmount: 2000000,
      tenor: 10,
      interestRate: 0.03,
      adminFeeAmount: 40000,
      disbursementDate: DateTime(2026, 8, 23),
      status: 'active',
      remainingBalance: 2000000,
      totalPaidPrincipal: 0,
      totalPaidInterest: 0,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(CreateLoanParams(
      memberId: '',
      principal: 0,
      tenor: 10,
    ));
  });

  late MockLoanRepository repository;
  late CreateLoan useCase;

  setUp(() {
    repository = MockLoanRepository();
    useCase = CreateLoan(repository);
  });

  test('valid loan delegates to repository', () async {
    when(() => repository.createLoan(
          memberId: any(named: 'memberId'),
          principal: any(named: 'principal'),
          tenor: any(named: 'tenor'),
          disbursementDate: any(named: 'disbursementDate'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => Ok(_fakeLoan()));

    final result = await useCase(const CreateLoanParams(
      memberId: 'm-1',
      principal: 2000000,
      tenor: 10,
    ));

    expect(result, isA<Ok<LoanEntity>>());
  });

  test('zero principal rejected', () async {
    final result = await useCase(const CreateLoanParams(
      memberId: 'm-1',
      principal: 0,
      tenor: 10,
    ));
    final message = switch (result) {
      Err(:final failure) => failure.message,
      Ok() => null,
    };
    expect(message, contains('lebih dari 0'));
    verifyNever(() => repository.createLoan(
          memberId: any(named: 'memberId'),
          principal: any(named: 'principal'),
          tenor: any(named: 'tenor'),
          disbursementDate: any(named: 'disbursementDate'),
          notes: any(named: 'notes'),
        ));
  });

  test('tenor above 50 rejected', () async {
    final result = await useCase(const CreateLoanParams(
      memberId: 'm-1',
      principal: 1000000,
      tenor: 60,
    ));
    expect(result, isA<Err<LoanEntity>>());
  });

  test('rateForType follows business rule (regular 2%, fast 3%)', () {
    expect(CreateLoanParams.rateForType('regular'), 0.02);
    expect(CreateLoanParams.rateForType('fast'), 0.03);
    // Biaya admin 3% untuk semua jenis pinjaman
    expect(CreateLoanParams.adminRateForType('regular'), 0.03);
    expect(CreateLoanParams.adminRateForType('fast'), 0.03);
  });
}
