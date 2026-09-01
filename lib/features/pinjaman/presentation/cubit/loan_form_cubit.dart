import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/loan_entities.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/usecases/create_loan.dart';

part 'loan_form_state.dart';

@injectable
class LoanFormCubit extends Cubit<LoanFormState> {
  LoanFormCubit(this._createLoan) : super(const LoanFormInitial());

  final CreateLoan _createLoan;

  Future<void> save({
    required String memberId,
    required double principal,
    required int tenor,
    DateTime? disbursementDate,
    String? notes,
    String loanType = 'regular',
  }) async {
    emit(const LoanFormSaving());
    final result = await _createLoan(CreateLoanParams(
      memberId: memberId,
      principal: principal,
      tenor: tenor,
      disbursementDate: disbursementDate,
      notes: notes,
      loanType: loanType,
    ));
    switch (result) {
      case Ok(:final value):
        emit(LoanFormSuccess(loan: value));
      case Err(:final failure):
        emit(LoanFormFailure(failure.message));
    }
  }

  void reset() => emit(const LoanFormInitial());
}
