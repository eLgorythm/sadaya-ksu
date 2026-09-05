import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/tax_entities.dart';
import '../../domain/usecases/tax_usecases.dart';

class PajakState {
  const PajakState({
    this.taxes = const [],
    this.loading = false,
    this.error,
    this.successMessage,
  });

  final List<TaxItem> taxes;
  final bool loading;
  final String? error;
  final String? successMessage;

  double get totalPaid =>
      taxes.where((t) => t.isPaid).fold(0.0, (sum, t) => sum + t.amount);

  double get totalUnpaid =>
      taxes.where((t) => !t.isPaid).fold(0.0, (sum, t) => sum + t.amount);

  PajakState copyWith({
    List<TaxItem>? taxes,
    bool? loading,
    String? error,
    String? successMessage,
  }) {
    return PajakState(
      taxes: taxes ?? this.taxes,
      loading: loading ?? this.loading,
      error: error,
      successMessage: successMessage,
    );
  }
}

@lazySingleton
class PajakCubit extends Cubit<PajakState> {
  PajakCubit(this._getTaxes, this._insertTax, this._updateTax, this._deleteTax)
    : super(const PajakState());

  final GetTaxes _getTaxes;
  final InsertTax _insertTax;
  final UpdateTax _updateTax;
  final DeleteTax _deleteTax;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final result = await _getTaxes();
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(loading: false, taxes: value));
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<void> insert(InsertTaxParams params) async {
    emit(state.copyWith(loading: true, error: null, successMessage: null));
    final result = await _insertTax(params);
    switch (result) {
      case Ok():
        await load(silent: true);
        emit(
          state.copyWith(
            loading: false,
            successMessage: 'Pajak berhasil ditambahkan',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<void> update(InsertTaxParams params, String id) async {
    emit(state.copyWith(loading: true, error: null, successMessage: null));
    final result = await _updateTax(params, id);
    switch (result) {
      case Ok():
        await load(silent: true);
        emit(
          state.copyWith(
            loading: false,
            successMessage: 'Pajak berhasil diupdate',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<void> delete(String id) async {
    emit(state.copyWith(loading: true, error: null, successMessage: null));
    final result = await _deleteTax(id);
    switch (result) {
      case Ok():
        await load(silent: true);
        emit(
          state.copyWith(
            loading: false,
            successMessage: 'Pajak berhasil dihapus',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  void clearMessages() {
    emit(state.copyWith(error: null, successMessage: null));
  }
}
