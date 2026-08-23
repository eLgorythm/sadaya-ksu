import 'package:flutter_test/flutter_test.dart';
import 'package:sadaya/features/pinjaman/domain/entities/loan_entities.dart';

void main() {
  group('InterestDistributionBreakdown (20 bagian)', () {
    test('exact split for round interest', () {
      // Jasa 200.000 -> Japinup 110rb, Kesra 50rb, SWK 20rb, 4x5rb
      final d = InterestDistributionBreakdown.fromInterest(200000);
      expect(d.japinup, 110000);
      expect(d.kesra, 50000);
      expect(d.swk, 20000);
      expect(d.sosial, 5000);
      expect(d.pendidikan, 5000);
      expect(d.crk, 5000);
      expect(d.pembangunan, 5000);

      final sum = d.japinup +
          d.kesra + d.swk + d.sosial +
          d.pendidikan + d.crk + d.pembangunan;
      expect(sum, 200000);
    });

    test('Japinup absorbs rounding so total always equals interest', () {
      // 33.333 tidak habis dibagi rapi
      const interest = 33333.0;
      final d = InterestDistributionBreakdown.fromInterest(interest);

      final sum = d.japinup +
          d.kesra + d.swk + d.sosial +
          d.pendidikan + d.crk + d.pembangunan;
      // Toleransi 1 sen: aritmetika double tidak eksak, sisi DB (NUMERIC) eksak.
      expect(sum, closeTo(interest, 0.01));
      expect((d.japinup - interest * 0.55).abs(), lessThan(1));
    });

    test('zero interest produces zero buckets', () {
      final d = InterestDistributionBreakdown.fromInterest(0);
      expect(d.totalInterest, 0);
      expect(d.japinup, 0);
      expect(d.swk, 0);
    });
  });

  group('LoanEntity helpers', () {
    test('monthly installment = principal/tenor + principal*rate', () {
      final loan = LoanEntity(
        id: 'l',
        loanNumber: 1,
        principalAmount: 1000000,
        tenor: 10,
        interestRate: 0.02,
        adminFeeAmount: 30000,
        disbursementDate: DateTime(2026),
        status: 'active',
        remainingBalance: 900000,
        totalPaidPrincipal: 100000,
        totalPaidInterest: 40000,
      );

      expect(loan.monthlyPrincipal, 100000);
      expect(loan.monthlyInterest, 20000);
      expect(loan.monthlyInstallment, 120000);
      expect(loan.progress, closeTo(0.1, 0.001));
      expect(loan.isActive, isTrue);
      expect(loan.isPaidOff, isFalse);
    });
  });
}
