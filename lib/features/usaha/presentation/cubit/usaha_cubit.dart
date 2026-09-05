import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/usaha_entities.dart';
import '../../domain/usecases/material_usecases.dart';
import '../../domain/usecases/production_usecases.dart';
import '../../domain/usecases/sale_usecases.dart';

part 'usaha_state.dart';

@lazySingleton
class UsahaCubit extends Cubit<UsahaState> {
  UsahaCubit(
    this._getMaterials,
    this._getMaterialTransactions,
    this._getProductions,
    this._getSales,
  ) : super(const UsahaInitial());

  final GetMaterials _getMaterials;
  final GetMaterialTransactions _getMaterialTransactions;
  final GetProductions _getProductions;
  final GetSales _getSales;

  /// Muat seluruh data unit usaha. [silent] menjaga tampilan tetap
  /// terlihat (tanpa spinner) bila data sudah ada — untuk pembaruan
  /// setelah tambah/hapus.
  Future<void> load({bool silent = false}) async {
    if (!silent || state is! UsahaLoaded) {
      emit(const UsahaLoadInProgress());
    }

    // Empat permintaan dijalankan paralel, bukan berurutan.
    final materialsFuture = _getMaterials(const NoParams());
    final transactionsFuture = _getMaterialTransactions(const NoParams());
    final productionsFuture = _getProductions(const NoParams());
    final salesFuture = _getSales(const NoParams());

    final materialsResult = await materialsFuture;
    final List<RawMaterial> materials;
    switch (materialsResult) {
      case Ok(:final value):
        materials = value;
      case Err(:final failure):
        if (!isClosed) emit(UsahaFailure(failure.message));
        return;
    }

    final txResult = await transactionsFuture;
    final List<MaterialTransaction> txs;
    switch (txResult) {
      case Ok(:final value):
        txs = value;
      case Err(:final failure):
        if (!isClosed) emit(UsahaFailure(failure.message));
        return;
    }

    final prodResult = await productionsFuture;
    final List<ProductionRecord> productions;
    switch (prodResult) {
      case Ok(:final value):
        productions = value;
      case Err(:final failure):
        if (!isClosed) emit(UsahaFailure(failure.message));
        return;
    }

    final salesResult = await salesFuture;
    final List<SaleRecord> sales;
    switch (salesResult) {
      case Ok(:final value):
        sales = value;
      case Err(:final failure):
        if (!isClosed) emit(UsahaFailure(failure.message));
        return;
    }

    if (!isClosed) {
      emit(
        UsahaLoaded(
          materials: materials,
          materialTransactions: txs,
          productions: productions,
          sales: sales,
        ),
      );
    }
  }

  /// Hapus penjualan langsung di memori — tanpa menunggu
  /// pengambilan ulang dari server.
  void removeSale(String saleId) {
    final current = state;
    if (current is! UsahaLoaded) return;
    if (!current.sales.any((s) => s.id == saleId)) return;
    if (isClosed) return;
    emit(
      UsahaLoaded(
        materials: current.materials,
        materialTransactions: current.materialTransactions,
        productions: current.productions,
        sales: current.sales.where((s) => s.id != saleId).toList(),
      ),
    );
  }
}
