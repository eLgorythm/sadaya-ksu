import 'package:equatable/equatable.dart';

class LoanEntity extends Equatable {
  const LoanEntity({
    required this.id,
    required this.loanNumber,
    required this.principalAmount,
    required this.tenor,
    required this.interestRate,
    required this.adminFeeAmount,
    required this.disbursementDate,
    required this.status,
    required this.remainingBalance,
    required this.totalPaidPrincipal,
    required this.totalPaidInterest,
    this.notes,
  });

  final String id;
  final int loanNumber;
  final double principalAmount;
  final int tenor;
  final double interestRate;
  final double adminFeeAmount;
  final DateTime disbursementDate;
  final String status;
  final double remainingBalance;
  final double totalPaidPrincipal;
  final double totalPaidInterest;
  final String? notes;

  bool get isActive => status == 'active';
  bool get isPaidOff => status == 'paid_off';

  double get monthlyPrincipal => principalAmount / tenor;
  double get monthlyInterest => principalAmount * interestRate;
  double get monthlyInstallment => monthlyPrincipal + monthlyInterest;
  double get totalPaid => totalPaidPrincipal + totalPaidInterest;

  /// Progress pelunasan 0.0 - 1.0
  double get progress =>
      principalAmount <= 0 ? 0 : (totalPaidPrincipal / principalAmount).clamp(0, 1);

  @override
  List<Object?> get props => [
        id, loanNumber, principalAmount, tenor, interestRate,
        adminFeeAmount, disbursementDate, status, remainingBalance,
        totalPaidPrincipal, totalPaidInterest, notes,
      ];
}

class InstallmentScheduleEntity extends Equatable {
  const InstallmentScheduleEntity({
    required this.id,
    required this.installmentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.status,
    this.paidDate,
  });

  final String id;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final String status;

  /// Tanggal pembayaran terakhir (dari installment_payments).
  /// Null bila belum ada pembayaran.
  final DateTime? paidDate;

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id, installmentNumber, dueDate, principalAmount,
        interestAmount, totalAmount, status, paidDate,
      ];
}

/// Rincian distribusi jasa (20 bagian) untuk satu pembayaran.
class InterestDistributionBreakdown extends Equatable {
  const InterestDistributionBreakdown({
    required this.totalInterest,
    required this.japinup,
    required this.kesra,
    required this.swk,
    required this.sosial,
    required this.pendidikan,
    required this.crk,
    required this.pembangunan,
  });

  final double totalInterest;
  final double japinup;
  final double kesra;
  final double swk;
  final double sosial;
  final double pendidikan;
  final double crk;
  final double pembangunan;

  /// Mirror logika RPC pay_installment (Japinup menyerap pembulatan).
  static InterestDistributionBreakdown fromInterest(double interest) {
    final swk = _round2(interest * 0.10);
    final kesra = _round2(interest * 0.25);
    final sosial = _round2(interest * 0.025);
    final pendidikan = _round2(interest * 0.025);
    final crk = _round2(interest * 0.025);
    final pembangunan = _round2(interest * 0.025);
    final japinup =
        _round2(interest - (swk + kesra + sosial + pendidikan + crk + pembangunan));
    return InterestDistributionBreakdown(
      totalInterest: interest,
      japinup: japinup,
      kesra: kesra,
      swk: swk,
      sosial: sosial,
      pendidikan: pendidikan,
      crk: crk,
      pembangunan: pembangunan,
    );
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  @override
  List<Object?> get props => [
        totalInterest, japinup, kesra, swk,
        sosial, pendidikan, crk, pembangunan,
      ];
}
