import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/saving_entities.dart';
import '../../domain/usecases/get_savings.dart';

part 'savings_state.dart';

@lazySingleton
class SavingsCubit extends Cubit<SavingsState> {
  SavingsCubit(this._getMemberSavings, this._getSavingsTypes)
      : super(const SavingsInitial());

  final GetMemberSavings _getMemberSavings;
  final GetSavingsTypes _getSavingsTypes;

  Future<void> load(String memberId) async {
    emit(SavingsLoadInProgress(memberId: memberId));
    final typesResult = await _getSavingsTypes(const NoParams());
    switch (typesResult) {
      case Ok(:final value):
        _types = value;
      case Err(:final failure):
        emit(SavingsFailure(
          message: failure.message,
          memberId: memberId,
        ));
        return;
    }
    final summaryResult = await _getMemberSavings(memberId);
    switch (summaryResult) {
      case Ok(:final value):
        emit(SavingsLoadSuccess(
          memberId: memberId,
          types: _types,
          summary: value,
        ));
      case Err(:final failure):
        emit(SavingsFailure(message: failure.message, memberId: memberId));
    }
  }

  List<SavingsTypeEntity> _types = const [];

  List<SavingsTypeEntity> get types => _types;
}
