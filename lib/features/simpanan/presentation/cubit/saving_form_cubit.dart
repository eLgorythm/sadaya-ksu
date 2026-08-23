import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/saving_entities.dart';
import '../../domain/usecases/create_saving_transaction.dart';

part 'saving_form_state.dart';

@injectable
class SavingFormCubit extends Cubit<SavingFormState> {
  SavingFormCubit(this._createTransaction)
      : super(const SavingFormInitial());

  final CreateSavingTransaction _createTransaction;

  Future<void> save({
    required String memberId,
    required SavingsTypeEntity type,
    required String transactionType,
    required double amount,
    String? description,
  }) async {
    emit(const SavingFormSaving());
    final result = await _createTransaction(CreateSavingTransactionParams(
      memberId: memberId,
      type: type,
      transactionType: transactionType,
      amount: amount,
      description: description,
    ));
    switch (result) {
      case Ok(:final value):
        emit(SavingFormSuccess(transaction: value));
      case Err(:final failure):
        emit(SavingFormFailure(failure.message));
    }
  }

  void reset() => emit(const SavingFormInitial());
}
