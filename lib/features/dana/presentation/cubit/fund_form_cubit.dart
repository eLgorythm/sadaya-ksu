import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/create_fund_entry.dart';

part 'fund_form_state.dart';

@injectable
class FundFormCubit extends Cubit<FundFormState> {
  FundFormCubit(this._createEntry) : super(const FundFormInitial());

  final CreateFundEntry _createEntry;

  void reset() => emit(const FundFormInitial());

  Future<void> save({
    required String fundType,
    required bool isIncoming,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    emit(const FundFormSaving());
    final result = await _createEntry(CreateFundEntryParams(
      fundType: fundType,
      isIncoming: isIncoming,
      amount: amount,
      date: date,
      description: description,
    ));
    switch (result) {
      case Ok():
        emit(const FundFormSuccess());
      case Err(:final failure):
        emit(FundFormFailure(failure.message));
    }
  }
}
