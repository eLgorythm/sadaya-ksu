import '../../domain/entities/loan_entities.dart';

class LoanModel extends LoanEntity {
  const LoanModel({
    required super.id,
    required super.loanNumber,
    required super.principalAmount,
    required super.tenor,
    required super.interestRate,
    required super.adminFeeAmount,
    required super.disbursementDate,
    required super.status,
    required super.remainingBalance,
    required super.totalPaidPrincipal,
    required super.totalPaidInterest,
    super.notes,
    super.loanType,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] as String,
      loanNumber: (map['loan_number'] as num).toInt(),
      principalAmount: double.tryParse('${map['principal_amount']}') ?? 0,
      tenor: (map['tenor'] as num).toInt(),
      interestRate: double.tryParse('${map['interest_rate']}') ?? 0,
      adminFeeAmount: double.tryParse('${map['admin_fee_amount']}') ?? 0,
      disbursementDate: DateTime.parse(map['disbursement_date'] as String),
      status: map['status'] as String,
      remainingBalance: double.tryParse('${map['remaining_balance']}') ?? 0,
      totalPaidPrincipal:
          double.tryParse('${map['total_paid_principal']}') ?? 0,
      totalPaidInterest: double.tryParse('${map['total_paid_interest']}') ?? 0,
      notes: map['notes'] as String?,
      loanType: map['loan_type'] as String? ?? 'regular',
    );
  }
}

class InstallmentScheduleModel extends InstallmentScheduleEntity {
  const InstallmentScheduleModel({
    required super.id,
    required super.installmentNumber,
    required super.dueDate,
    required super.principalAmount,
    required super.interestAmount,
    required super.totalAmount,
    required super.status,
    super.paidDate,
  });

  /// [map] berasal dari select dengan embed pembayaran:
  /// `*, installment_payments(payment_date)` — ambil tanggal terbaru.
  factory InstallmentScheduleModel.fromMap(Map<String, dynamic> map) {
    DateTime? paidDate;
    final payments = map['installment_payments'];
    if (payments is List && payments.isNotEmpty) {
      for (final p in payments) {
        if (p is Map<String, dynamic> && p['payment_date'] != null) {
          final d = DateTime.tryParse(p['payment_date'].toString());
          if (d != null && (paidDate == null || d.isAfter(paidDate))) {
            paidDate = d;
          }
        }
      }
    }
    return InstallmentScheduleModel(
      id: map['id'] as String,
      installmentNumber: (map['installment_number'] as num).toInt(),
      dueDate: DateTime.parse(map['due_date'] as String),
      principalAmount: double.tryParse('${map['principal_amount']}') ?? 0,
      interestAmount: double.tryParse('${map['interest_amount']}') ?? 0,
      totalAmount: double.tryParse('${map['total_amount']}') ?? 0,
      status: map['status'] as String,
      paidDate: paidDate,
    );
  }
}
