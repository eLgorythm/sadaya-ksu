part of 'saving_form_cubit.dart';

sealed class SavingFormState extends Equatable {
  const SavingFormState();

  @override
  List<Object?> get props => [];
}

class SavingFormInitial extends SavingFormState {
  const SavingFormInitial();
}

class SavingFormSaving extends SavingFormState {
  const SavingFormSaving();
}

class SavingFormSuccess extends SavingFormState {
  const SavingFormSuccess({required this.transaction});

  final SavingTransactionEntity transaction;

  @override
  List<Object?> get props => [transaction];
}

class SavingFormFailure extends SavingFormState {
  const SavingFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
