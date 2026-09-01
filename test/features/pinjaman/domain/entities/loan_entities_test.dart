import 'package:flutter_test/flutter_test.dart';
import 'package:sadaya/features/pinjaman/domain/entities/loan_entities.dart';

void main() {
  group('InterestDistributionBreakdown (100% bunga → 7 pos)', () {
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

    test('fast (dasar 3): membagi 100% bunga, total sama dengan bunga', () {
      // Bunga 1.000.000, dasar 3: Japinup 2,10/3, Kesra 0,50/3, SWK 0,20/3,
      // dan Sosial/Pendidikan/CRK/Pembangunan 0,05/3.
      const interest = 1000000.0;
      final d = InterestDistributionBreakdown.fromInterest(interest, base: 3.0);
      expect(d.japinup, closeTo(interest * 2.10 / 3.00, 0.5));
      expect(d.kesra, closeTo(interest * 0.50 / 3.00, 0.5));
      expect(d.swk, closeTo(interest * 0.20 / 3.00, 0.5));
      expect(d.sosial, closeTo(interest * 0.05 / 3.00, 0.5));
      expect(d.pendidikan, closeTo(interest * 0.05 / 3.00, 0.5));
      expect(d.crk, closeTo(interest * 0.05 / 3.00, 0.5));
      expect(d.pembangunan, closeTo(interest * 0.05 / 3.00, 0.5));
      final sum = d.japinup + d.kesra + d.swk + d.sosial +
          d.pendidikan + d.crk + d.pembangunan;
      expect(sum, closeTo(interest, 0.01));
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
      // Bunga/jasa angsur = 2% x pokok, merata per bulan = 2% x 1jt / 10 = 2.000
      expect(loan.monthlyInterest, 2000);
      expect(loan.monthlyInstallment, 102000);
      expect(loan.progress, closeTo(0.1, 0.001));
      expect(loan.isActive, isTrue);
      expect(loan.isPaidOff, isFalse);
    });
  });
}
