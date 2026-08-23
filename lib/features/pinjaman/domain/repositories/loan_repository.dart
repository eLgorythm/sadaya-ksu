import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/loan_entities.dart';

class LoanDetail {
  const LoanDetail({required this.loan, required this.schedules});

  final LoanEntity loan;
  final List<InstallmentScheduleEntity> schedules;
}

abstract interface class LoanRepository {
  Future<Result<List<LoanEntity>>> getMemberLoans(String memberId);

  Future<Result<LoanDetail>> getLoanDetail(String loanId);

  Future<Result<LoanEntity>> createLoan({
    required String memberId,
    required double principal,
    required int tenor,
    DateTime? disbursementDate,
    String? notes,
  });

  Future<Result<void>> payInstallment({
    required String scheduleId,
    double? principalPaid,
    double? interestPaid,
  });
}

class CreateLoanParams extends Equatable {
  const CreateLoanParams({
    required this.memberId,
    required this.principal,
    required this.tenor,
    this.disbursementDate,
    this.notes,
  });

  final String memberId;
  final double principal;
  final int tenor;
  final DateTime? disbursementDate;
  final String? notes;

  /// Bunga sesuai aturan: tenor >= 10 bulan -> 2%, < 10 -> 3%.
  static double rateForTenor(int tenor) => tenor < 10 ? 0.03 : 0.02;

  @override
  List<Object?> get props =>
      [memberId, principal, tenor, disbursementDate, notes];
}
