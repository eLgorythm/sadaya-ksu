import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/loan_entities.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/usecases/get_loans.dart';

part 'loans_state.dart';

@lazySingleton
class LoansCubit extends Cubit<LoansState> {
  LoansCubit(this._getMemberLoans, this._loanRepository)
      : super(const LoansInitial());

  final GetMemberLoans _getMemberLoans;
  final LoanRepository _loanRepository;

  Future<void> load(String memberId) async {
    emit(LoansLoadInProgress(memberId: memberId));
    final result = await _getMemberLoans(memberId);
    switch (result) {
      case Ok(:final value):
        emit(LoansListLoaded(memberId: memberId, loans: value));
      case Err(:final failure):
        emit(LoansFailure(message: failure.message, memberId: memberId));
    }
  }

  Future<void> openDetail({
    required String memberId,
    required String loanId,
  }) async {
    emit(LoansLoadInProgress(memberId: memberId));
    final result = await _loanRepository.getLoanDetail(loanId);
    switch (result) {
      case Ok(:final value):
        emit(LoansDetailLoaded(memberId: memberId, detail: value));
      case Err(:final failure):
        emit(LoansFailure(message: failure.message, memberId: memberId));
    }
  }

  /// Dipanggil setelah pembayaran cicilan sukses — muat ulang detail.
  Future<void> refreshDetail({required String memberId}) async {
    final current = state;
    if (current is! LoansDetailLoaded) return;
    final result =
        await _loanRepository.getLoanDetail(current.detail.loan.id);
    switch (result) {
      case Ok(:final value):
        emit(LoansDetailLoaded(
          memberId: memberId,
          detail: value,
          justPaid: true,
        ));
      case Err():
        break;
    }
  }

  void backToList(String memberId) => load(memberId);
}
