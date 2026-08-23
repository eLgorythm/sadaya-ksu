part of 'loan_payment_cubit.dart';

sealed class LoanPaymentState extends Equatable {
  const LoanPaymentState();

  @override
  List<Object?> get props => [];
}

class LoanPaymentInitial extends LoanPaymentState {
  const LoanPaymentInitial();
}

class LoanPaymentInProgress extends LoanPaymentState {
  const LoanPaymentInProgress();
}

class LoanPaymentSuccess extends LoanPaymentState {
  const LoanPaymentSuccess();
}

class LoanPaymentFailure extends LoanPaymentState {
  const LoanPaymentFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
