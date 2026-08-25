part of 'cash_form_cubit.dart';

sealed class CashFormState extends Equatable {
  const CashFormState();

  @override
  List<Object?> get props => [];
}

class CashFormInitial extends CashFormState {
  const CashFormInitial();
}

class CashFormSaving extends CashFormState {
  const CashFormSaving();
}

class CashFormSuccess extends CashFormState {
  const CashFormSuccess();
}

class CashFormFailure extends CashFormState {
  const CashFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
