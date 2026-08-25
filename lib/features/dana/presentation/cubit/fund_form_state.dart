part of 'fund_form_cubit.dart';

sealed class FundFormState extends Equatable {
  const FundFormState();

  @override
  List<Object?> get props => [];
}

class FundFormInitial extends FundFormState {
  const FundFormInitial();
}

class FundFormSaving extends FundFormState {
  const FundFormSaving();
}

class FundFormSuccess extends FundFormState {
  const FundFormSuccess();
}

class FundFormFailure extends FundFormState {
  const FundFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
