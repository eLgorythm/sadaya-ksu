part of 'loans_cubit.dart';

sealed class LoansState extends Equatable {
  const LoansState();

  @override
  List<Object?> get props => [];
}

class LoansInitial extends LoansState {
  const LoansInitial();
}

class LoansLoadInProgress extends LoansState {
  const LoansLoadInProgress({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

class LoansListLoaded extends LoansState {
  const LoansListLoaded({required this.memberId, required this.loans});

  final String memberId;
  final List<LoanEntity> loans;

  @override
  List<Object?> get props => [memberId, loans];
}

class LoansDetailLoaded extends LoansState {
  const LoansDetailLoaded({
    required this.memberId,
    required this.detail,
  });

  final String memberId;
  final LoanDetail detail;

  @override
  List<Object?> get props => [memberId, detail];
}

class LoansFailure extends LoansState {
  const LoansFailure({required this.memberId, required this.message});

  final String memberId;
  final String message;

  @override
  List<Object?> get props => [memberId, message];
}
