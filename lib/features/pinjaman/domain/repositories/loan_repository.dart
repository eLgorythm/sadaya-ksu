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
    String loanType = 'regular',
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
    this.loanType = 'regular',
  });

  final String memberId;
  final double principal;
  final int tenor;
  final DateTime? disbursementDate;
  final String? notes;

  /// 'regular' = mengangsur bulanan; 'fast' = bayar full di akhir tenor.
  final String loanType;

  /// Bunga/jasa = persen x total pokok: angsur 2%, cepat 3% (flat).
  static double rateForType(String loanType) =>
      loanType == 'fast' ? 0.03 : 0.02;

  bool get isFast => loanType == 'fast';

  /// Biaya administrasi potongan awal = 3% x pokok (30rb/1jt) semua jenis.
  static double adminRateForType(String loanType) => 0.03;

  @override
  List<Object?> get props => [
    memberId,
    principal,
    tenor,
    disbursementDate,
    notes,
    loanType,
  ];
}
