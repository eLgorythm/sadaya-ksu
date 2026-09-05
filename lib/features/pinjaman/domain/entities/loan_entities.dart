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
    this.loanType = 'regular',
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

  /// 'regular' = mengangsur bulanan; 'fast' = bayar full di akhir tenor.
  final String loanType;

  bool get isActive => status == 'active';
  bool get isPaidOff => status == 'paid_off';
  bool get isFast => loanType == 'fast';

  double get monthlyPrincipal => principalAmount / tenor;

  /// Bunga per bulan (pinjaman angsur): total bunga 2% x pokok, merata /tenor.
  double get monthlyInterest => principalAmount * interestRate / tenor;

  /// Total bunga pinjaman cepat (flat 3% x pokok).
  double get fastTotalInterest => principalAmount * interestRate;

  double get monthlyInstallment => monthlyPrincipal + monthlyInterest;
  double get totalPaid => totalPaidPrincipal + totalPaidInterest;

  /// Progress pelunasan 0.0 - 1.0
  double get progress => principalAmount <= 0
      ? 0
      : (totalPaidPrincipal / principalAmount).clamp(0, 1);

  @override
  List<Object?> get props => [
    id,
    loanNumber,
    principalAmount,
    tenor,
    interestRate,
    adminFeeAmount,
    disbursementDate,
    status,
    remainingBalance,
    totalPaidPrincipal,
    totalPaidInterest,
    notes,
    loanType,
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
    id,
    installmentNumber,
    dueDate,
    principalAmount,
    interestAmount,
    totalAmount,
    status,
    paidDate,
  ];
}

/// Rincian distribusi jasa untuk satu pembayaran.
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

  /// Mirror logika RPC pay_installment: membagi 100% BUNGA ke 7 pos.
  /// [base] = penyebut distribusi: 2 utk angsur (bunga 2% pokok),
  /// 3 utk cepat (bunga 3% pokok). Total selalu = interest. Japinup menyerap.
  static InterestDistributionBreakdown fromInterest(
    double interest, {
    double base = 2.0,
  }) {
    final swk = _round2(interest * 0.20 / base);
    final kesra = _round2(interest * 0.50 / base);
    final sosial = _round2(interest * 0.05 / base);
    final pendidikan = _round2(interest * 0.05 / base);
    final crk = _round2(interest * 0.05 / base);
    final pembangunan = _round2(interest * 0.05 / base);
    final japinup = _round2(
      interest - (swk + kesra + sosial + pendidikan + crk + pembangunan),
    );
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
    totalInterest,
    japinup,
    kesra,
    swk,
    sosial,
    pendidikan,
    crk,
    pembangunan,
  ];
}
