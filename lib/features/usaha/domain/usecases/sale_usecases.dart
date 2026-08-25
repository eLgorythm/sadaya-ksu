import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/usaha_entities.dart';
import '../repositories/usaha_repository.dart';

@lazySingleton
class GetSales implements UseCase<List<SaleRecord>, NoParams> {
  GetSales(this._repository);

  final UsahaRepository _repository;

  @override
  Future<Result<List<SaleRecord>>> call(NoParams _) =>
      _repository.getSales();
}

class CreateSaleParams {
  const CreateSaleParams({
    required this.productType,
    required this.date,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.buyer,
    this.notes,
  });

  final String productType;
  final DateTime date;
  final double quantity;

  /// 'kg', 'gram', atau 'pack'.
  final String unit;
  final double unitPrice;
  final String? buyer;
  final String? notes;
}

@lazySingleton
class CreateSale {
  CreateSale(this._repository);

  final UsahaRepository _repository;

  Future<Result<void>> call(CreateSaleParams params) async {
    if (!kProductLabels.containsKey(params.productType)) {
      return const Err(Failure(message: 'Jenis produk tidak dikenal'));
    }
    if (!['kg', 'gram', 'pack'].contains(params.unit)) {
      return const Err(Failure(message: 'Satuan penjualan tidak dikenal'));
    }
    if (params.quantity <= 0) {
      return const Err(Failure(message: 'Jumlah terjual harus lebih dari 0'));
    }
    if (params.unitPrice <= 0) {
      return const Err(Failure(message: 'Harga satuan harus lebih dari 0'));
    }
    if (params.date.isAfter(DateTime.now())) {
      return const Err(
          Failure(message: 'Tanggal penjualan tidak boleh di masa depan'));
    }
    return _repository.createSale(
      productType: params.productType,
      date: params.date,
      quantity: params.quantity,
      unit: params.unit,
      unitPrice: params.unitPrice,
      buyer: params.buyer?.trim(),
      notes: params.notes?.trim(),
    );
  }
}

/// Menghapus catatan penjualan.
@lazySingleton
class DeleteSale {
  DeleteSale(this._repository);

  final UsahaRepository _repository;

  Future<Result<void>> call(String saleId) => _repository.deleteSale(saleId);
}
