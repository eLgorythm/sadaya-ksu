import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/aset_entities.dart';
import '../../domain/usecases/aset_usecases.dart';

part 'aset_state.dart';

@lazySingleton
class AsetCubit extends Cubit<AsetState> {
  AsetCubit(this._getAssets, this._getDepreciations, this._recalculate)
    : super(const AsetInitial());

  final GetAssets _getAssets;
  final GetDepreciations _getDepreciations;
  final RecalculateDepreciations _recalculate;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  /// Memuat aset + buku penyusutan untuk tahun terpilih.
  Future<void> load({int? year}) async {
    if (year != null) _selectedYear = year;
    emit(AsetLoadInProgress(selectedYear: _selectedYear));

    final assetResult = await _getAssets(const NoParams());
    final List<AssetItem> assets;
    switch (assetResult) {
      case Ok(:final value):
        assets = value;
      case Err(:final failure):
        if (!isClosed) emit(AsetFailure(failure.message));
        return;
    }

    final depResult = await _getDepreciations(_selectedYear);
    final List<DepreciationRow> rows;
    switch (depResult) {
      case Ok(:final value):
        rows = value;
      case Err(:final failure):
        if (!isClosed) emit(AsetFailure(failure.message));
        return;
    }

    if (!isClosed) {
      emit(
        AsetLoaded(
          assets: assets,
          depreciationRows: rows,
          selectedYear: _selectedYear,
        ),
      );
    }
  }

  /// Jalankan perhitungan penyusutan server untuk tahun terpilih
  /// lalu muat ulang. Mengembalikan jumlah baris yang dibuat.
  Future<Result<int>> recalculate() async {
    final result = await _recalculate(_selectedYear);
    switch (result) {
      case Ok():
        await load();
      case Err():
        break;
    }
    return result;
  }
}
