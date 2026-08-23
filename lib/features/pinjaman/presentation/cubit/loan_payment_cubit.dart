import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/pay_installment.dart';

part 'loan_payment_state.dart';

@injectable
class LoanPaymentCubit extends Cubit<LoanPaymentState> {
  LoanPaymentCubit(this._payInstallment)
      : super(const LoanPaymentInitial());

  final PayInstallment _payInstallment;

  Future<void> pay({
    required String scheduleId,
    double? principalPaid,
    double? interestPaid,
  }) async {
    emit(const LoanPaymentInProgress());
    final result = await _payInstallment(PayInstallmentParams(
      scheduleId: scheduleId,
      principalPaid: principalPaid,
      interestPaid: interestPaid,
    ));
    switch (result) {
      case Ok():
        emit(const LoanPaymentSuccess());
      case Err(:final failure):
        emit(LoanPaymentFailure(failure.message));
    }
  }

  void reset() => emit(const LoanPaymentInitial());
}
