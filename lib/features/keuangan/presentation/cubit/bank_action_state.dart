part of 'bank_action_cubit.dart';

sealed class BankActionState extends Equatable {
  const BankActionState();

  @override
  List<Object?> get props => [];
}

class BankActionInitial extends BankActionState {
  const BankActionInitial();
}

class BankActionSaving extends BankActionState {
  const BankActionSaving();
}

class BankActionSuccess extends BankActionState {
  const BankActionSuccess();
}

class BankActionFailure extends BankActionState {
  const BankActionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
