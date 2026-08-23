part of 'savings_cubit.dart';

sealed class SavingsState extends Equatable {
  const SavingsState({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

class SavingsInitial extends SavingsState {
  const SavingsInitial() : super(memberId: '');
}

class SavingsLoadInProgress extends SavingsState {
  const SavingsLoadInProgress({required super.memberId});
}

class SavingsLoadSuccess extends SavingsState {
  const SavingsLoadSuccess({
    required super.memberId,
    required this.types,
    required this.summary,
  });

  final List<SavingsTypeEntity> types;
  final MemberSavingsSummary summary;

  @override
  List<Object?> get props => [...super.props, types, summary];
}

class SavingsFailure extends SavingsState {
  const SavingsFailure({required super.memberId, required this.message});

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
