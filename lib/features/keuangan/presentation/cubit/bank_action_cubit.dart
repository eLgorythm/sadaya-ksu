import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/bank_action.dart';

part 'bank_action_state.dart';

@injectable
class BankActionCubit extends Cubit<BankActionState> {
  BankActionCubit(this._action) : super(const BankActionInitial());

  final BankActionEntry _action;

  Future<void> save(BankActionParams params) async {
    emit(const BankActionSaving());
    final result = await _action(params);
    switch (result) {
      case Ok():
        emit(const BankActionSuccess());
      case Err(:final failure):
        emit(BankActionFailure(failure.message));
    }
  }
}