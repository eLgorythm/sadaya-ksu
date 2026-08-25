part of 'shu_form_cubit.dart';

sealed class ShuFormState extends Equatable {
  const ShuFormState();

  @override
  List<Object?> get props => [];
}

class ShuFormInitial extends ShuFormState {
  const ShuFormInitial();
}

class ShuFormSaving extends ShuFormState {
  const ShuFormSaving();
}

class ShuFormSuccess extends ShuFormState {
  const ShuFormSuccess();
}

class ShuFormFailure extends ShuFormState {
  const ShuFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
