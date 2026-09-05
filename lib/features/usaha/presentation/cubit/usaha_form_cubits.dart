import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/material_usecases.dart';
import '../../domain/usecases/production_usecases.dart';
import '../../domain/usecases/sale_usecases.dart';

// ---------------------------------------------------------------------------
// State bersama untuk semua form unit usaha
// ---------------------------------------------------------------------------
sealed class UsahaFormState extends Equatable {
  const UsahaFormState();

  @override
  List<Object?> get props => [];
}

class UsahaFormInitial extends UsahaFormState {
  const UsahaFormInitial();
}

class UsahaFormSaving extends UsahaFormState {
  const UsahaFormSaving();
}

class UsahaFormSuccess extends UsahaFormState {
  const UsahaFormSuccess();
}

class UsahaFormFailure extends UsahaFormState {
  const UsahaFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Tambah bahan baku baru.
@Injectable()
class MaterialFormCubit extends Cubit<UsahaFormState> {
  MaterialFormCubit(this._createMaterial) : super(const UsahaFormInitial());

  final CreateMaterial _createMaterial;

  void reset() => emit(const UsahaFormInitial());

  Future<void> save({required String name, required String unit}) async {
    emit(const UsahaFormSaving());
    final result = await _createMaterial(
      CreateMaterialParams(name: name, unit: unit),
    );
    switch (result) {
      case Ok():
        emit(const UsahaFormSuccess());
      case Err(:final failure):
        emit(UsahaFormFailure(failure.message));
    }
  }
}

/// Catat pembelian / pemakaian bahan baku.
@Injectable()
class MaterialTxFormCubit extends Cubit<UsahaFormState> {
  MaterialTxFormCubit(this._record) : super(const UsahaFormInitial());

  final RecordMaterialTransaction _record;

  void reset() => emit(const UsahaFormInitial());

  Future<void> save({
    required String materialId,
    required bool isPurchase,
    required double quantity,
    double? unitPrice,
    required DateTime date,
    String? notes,
  }) async {
    emit(const UsahaFormSaving());
    final result = await _record(
      RecordMaterialTxParams(
        materialId: materialId,
        isPurchase: isPurchase,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        notes: notes,
      ),
    );
    switch (result) {
      case Ok():
        emit(const UsahaFormSuccess());
      case Err(:final failure):
        emit(UsahaFormFailure(failure.message));
    }
  }
}

/// Catat hasil produksi.
@Injectable()
class ProductionFormCubit extends Cubit<UsahaFormState> {
  ProductionFormCubit(this._createProduction) : super(const UsahaFormInitial());

  final CreateProduction _createProduction;

  void reset() => emit(const UsahaFormInitial());

  Future<void> save({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    double? quantityPack,
    double? cost,
    String? notes,
  }) async {
    emit(const UsahaFormSaving());
    final result = await _createProduction(
      CreateProductionParams(
        productType: productType,
        date: date,
        quantity: quantity,
        unit: unit,
        quantityPack: quantityPack,
        cost: cost,
        notes: notes,
      ),
    );
    switch (result) {
      case Ok():
        emit(const UsahaFormSuccess());
      case Err(:final failure):
        emit(UsahaFormFailure(failure.message));
    }
  }
}

/// Catat penjualan produk.
@Injectable()
class SaleFormCubit extends Cubit<UsahaFormState> {
  SaleFormCubit(this._createSale) : super(const UsahaFormInitial());

  final CreateSale _createSale;

  void reset() => emit(const UsahaFormInitial());

  Future<void> save({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    required double unitPrice,
    String? buyer,
    String? notes,
  }) async {
    emit(const UsahaFormSaving());
    final result = await _createSale(
      CreateSaleParams(
        productType: productType,
        date: date,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        buyer: buyer,
        notes: notes,
      ),
    );
    switch (result) {
      case Ok():
        emit(const UsahaFormSuccess());
      case Err(:final failure):
        emit(UsahaFormFailure(failure.message));
    }
  }
}
