part of 'loan_form_cubit.dart';

sealed class LoanFormState extends Equatable {
  const LoanFormState();

  @override
  List<Object?> get props => [];
}

class LoanFormInitial extends LoanFormState {
  const LoanFormInitial();
}

class LoanFormSaving extends LoanFormState {
  const LoanFormSaving();
}

class LoanFormSuccess extends LoanFormState {
  const LoanFormSuccess({required this.loan});

  final LoanEntity loan;

  @override
  List<Object?> get props => [loan];
}

class LoanFormFailure extends LoanFormState {
  const LoanFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
