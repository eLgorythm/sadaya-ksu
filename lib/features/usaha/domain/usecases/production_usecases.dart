import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/usaha_entities.dart';
import '../repositories/usaha_repository.dart';

@lazySingleton
class GetProductions implements UseCase<List<ProductionRecord>, NoParams> {
  GetProductions(this._repository);

  final UsahaRepository _repository;

  @override
  Future<Result<List<ProductionRecord>>> call(NoParams _) =>
      _repository.getProductions();
}

class CreateProductionParams {
  const CreateProductionParams({
    required this.productType,
    required this.date,
    required this.quantity,
    required this.unit,
    this.quantityPack,
    this.cost,
    this.notes,
  });

  final String productType;
  final DateTime date;

  /// Hasil bulk dengan satuan bebas (kg/gram).
  final double quantity;
  final String unit;

  /// Hasil packing — opsional.
  final double? quantityPack;
  final double? cost;
  final String? notes;
}

@lazySingleton
class CreateProduction {
  CreateProduction(this._repository);

  final UsahaRepository _repository;

  Future<Result<void>> call(CreateProductionParams params) async {
    if (!kProductLabels.containsKey(params.productType)) {
      return const Err(Failure(message: 'Jenis produk tidak dikenal'));
    }
    if (!['kg', 'gram'].contains(params.unit)) {
      return const Err(Failure(message: 'Satuan produksi tidak dikenal'));
    }
    if (params.quantity <= 0) {
      return const Err(
          Failure(message: 'Jumlah produksi harus lebih dari 0'));
    }
    if (params.quantityPack != null && params.quantityPack! < 0) {
      return const Err(Failure(message: 'Jumlah pack tidak valid'));
    }
    if (params.cost != null && params.cost! < 0) {
      return const Err(Failure(message: 'Biaya produksi tidak boleh negatif'));
    }
    if (params.date.isAfter(DateTime.now())) {
      return const Err(
          Failure(message: 'Tanggal produksi tidak boleh di masa depan'));
    }
    return _repository.createProduction(
      productType: params.productType,
      date: params.date,
      quantity: params.quantity,
      unit: params.unit,
      quantityPack:
          (params.quantityPack != null && params.quantityPack! > 0)
              ? params.quantityPack
              : null,
      cost: params.cost,
      notes: params.notes?.trim(),
    );
  }
}
