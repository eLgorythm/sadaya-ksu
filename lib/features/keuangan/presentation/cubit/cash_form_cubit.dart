import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/create_cash_entry.dart';

part 'cash_form_state.dart';

@injectable
class CashFormCubit extends Cubit<CashFormState> {
  CashFormCubit(this._createEntry) : super(const CashFormInitial());

  final CreateCashEntry _createEntry;

  void reset() => emit(const CashFormInitial());

  Future<void> save({
    required String book,
    required String direction,
    required String counterAccount,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    emit(const CashFormSaving());
    final result = await _createEntry(CreateCashEntryParams(
      book: book,
      direction: direction,
      counterAccount: counterAccount,
      amount: amount,
      date: date,
      description: description,
    ));
    switch (result) {
      case Ok():
        emit(const CashFormSuccess());
      case Err(:final failure):
        emit(CashFormFailure(failure.message));
    }
  }
}
