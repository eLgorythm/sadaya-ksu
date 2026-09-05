import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/dana_entities.dart';
import '../../domain/usecases/dana_actions.dart';
import '../../domain/usecases/get_dana_data.dart';

part 'dana_state.dart';

@lazySingleton
class DanaCubit extends Cubit<DanaState> {
  DanaCubit(
    this._getFundTransactions,
    this._getLedgerBalances,
    this._getShuDistributions,
    this._approveShu,
    this._distributeShu,
    this._deleteShu,
    this._cancelDistribution,
  ) : super(const DanaInitial());

  final GetFundTransactions _getFundTransactions;
  final GetLedgerBalances _getLedgerBalances;
  final GetShuDistributions _getShuDistributions;
  final ApproveShu _approveShu;
  final DistributeShu _distributeShu;
  final DeleteShu _deleteShu;
  final CancelShuDistribution _cancelDistribution;

  /// Memuat ulang seluruh data modul dana & SHU.
  Future<void> load({bool silent = false}) async {
    if (!silent || state is! DanaLoaded) {
      emit(const DanaLoadInProgress());
    }

    final fundResult = await _getFundTransactions(const NoParams());
    final List<FundTransaction> funds;
    switch (fundResult) {
      case Ok(:final value):
        funds = value;
      case Err(:final failure):
        if (!isClosed) emit(DanaFailure(failure.message));
        return;
    }

    final ledgerResult = await _getLedgerBalances(DateTime.now().year);
    final List<LedgerBalance> ledgerBalances;
    switch (ledgerResult) {
      case Ok(:final value):
        ledgerBalances = value;
      case Err(:final failure):
        if (!isClosed) emit(DanaFailure(failure.message));
        return;
    }

    final shuResult = await _getShuDistributions(const NoParams());
    final List<ShuDistribution> shus;
    switch (shuResult) {
      case Ok(:final value):
        shus = value;
      case Err(:final failure):
        if (!isClosed) emit(DanaFailure(failure.message));
        return;
    }

    if (!isClosed) {
      emit(
        DanaLoaded(
          fundEntries: funds,
          ledgerBalances: ledgerBalances,
          shuList: shus,
        ),
      );
    }
  }

  /// Menyetujui draft SHU (draft → disetujui).
  Future<Result<void>> approveShu(String distributionId) =>
      _approveShu(distributionId);

  /// Mendistribusikan SHU (disetujui → terdistribusi)
  /// sekaligus mencatat alokasi di buku dana.
  Future<Result<void>> distribute(String distributionId) =>
      _distributeShu(distributionId);

  /// Menghapus SHU yang belum terdistribusi.
  Future<Result<void>> deleteShu(String distributionId) =>
      _deleteShu(distributionId);

  /// Membatalkan distribusi: alokasi dicabut, kembali ke draft.
  Future<Result<void>> cancelDistribution(String distributionId) =>
      _cancelDistribution(distributionId);
}
