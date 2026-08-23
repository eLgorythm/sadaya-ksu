part of 'member_form_cubit.dart';

sealed class MemberFormState extends Equatable {
  const MemberFormState();

  @override
  List<Object?> get props => [];
}

class MemberFormInitial extends MemberFormState {
  const MemberFormInitial();
}

class MemberFormSaving extends MemberFormState {
  const MemberFormSaving();
}

class MemberFormSuccess extends MemberFormState {
  const MemberFormSuccess({required this.member, required this.isEdit});

  final MemberEntity member;
  final bool isEdit;

  @override
  List<Object?> get props => [member, isEdit];
}

class MemberFormFailure extends MemberFormState {
  const MemberFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
