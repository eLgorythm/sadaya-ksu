import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/create_shu_distribution.dart';
import '../../domain/usecases/dana_actions.dart';

part 'shu_form_state.dart';

@injectable
class ShuFormCubit extends Cubit<ShuFormState> {
  ShuFormCubit(this._createShu, this._updateShu, this._approveShu)
      : super(const ShuFormInitial());

  final CreateShuDistribution _createShu;
  final UpdateShuDistribution _updateShu;
  final ApproveShu _approveShu;

  void reset() => emit(const ShuFormInitial());

  Future<void> save({
    String? existingId,
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberDividendPct,
    double? managementPct,
    String? notes,
    bool approveAfterSave = false,
  }) async {
    emit(const ShuFormSaving());
    final params = CreateShuDistributionParams(
      fiscalYear: fiscalYear,
      totalShu: totalShu,
      taxAmount: taxAmount,
      reservePct: reservePct,
      socialPct: socialPct,
      educationPct: educationPct,
      memberDividendPct: memberDividendPct,
      managementPct: managementPct,
      notes: notes,
    );

    if (existingId != null) {
      final updateResult = await _updateShu(existingId, params);
      switch (updateResult) {
        case Ok():
          break;
        case Err(:final failure):
          emit(ShuFormFailure(failure.message));
          return;
      }
      if (approveAfterSave) {
        final approveResult = await _approveShu(existingId);
        switch (approveResult) {
          case Ok():
            break;
          case Err(:final failure):
            emit(ShuFormFailure(
                'Tersimpan tapi gagal menyetujui: ${failure.message}'));
            return;
        }
      }
      emit(const ShuFormSuccess());
      return;
    }

    final result = await _createShu(params);
    String? shuId;
    switch (result) {
      case Ok(:final value):
        shuId = value;
      case Err(:final failure):
        emit(ShuFormFailure(failure.message));
        return;
    }

    if (approveAfterSave) {
      final approveResult = await _approveShu(shuId);
      switch (approveResult) {
        case Ok():
          break;
        case Err(:final failure):
          emit(ShuFormFailure(
              'Tersimpan tapi gagal menyetujui: ${failure.message}'));
          return;
      }
    }
    emit(const ShuFormSuccess());
  }
}
