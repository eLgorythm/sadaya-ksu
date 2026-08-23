import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/loan_repository.dart';

class PayInstallmentParams extends Equatable {
  const PayInstallmentParams({
    required this.scheduleId,
    this.principalPaid,
    this.interestPaid,
  });

  final String scheduleId;
  final double? principalPaid;
  final double? interestPaid;

  @override
  List<Object?> get props => [scheduleId, principalPaid, interestPaid];
}

@lazySingleton
class PayInstallment implements UseCase<void, PayInstallmentParams> {
  PayInstallment(this._repository);

  final LoanRepository _repository;

  @override
  Future<Result<void>> call(PayInstallmentParams params) async {
    if (params.scheduleId.isEmpty) {
      return const Err(Failure(message: 'Jadwal cicilan tidak valid'));
    }
    return _repository.payInstallment(
      scheduleId: params.scheduleId,
      principalPaid: params.principalPaid,
      interestPaid: params.interestPaid,
    );
  }
}
