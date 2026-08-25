import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/usaha_entities.dart';
import '../repositories/usaha_repository.dart';

@lazySingleton
class GetMaterials implements UseCase<List<RawMaterial>, NoParams> {
  GetMaterials(this._repository);

  final UsahaRepository _repository;

  @override
  Future<Result<List<RawMaterial>>> call(NoParams _) =>
      _repository.getMaterials();
}

class CreateMaterialParams {
  const CreateMaterialParams({
    required this.name,
    required this.unit,
  });

  final String name;
  final String unit;
}

/// Daftarkan jenis bahan baku baru (master data saja —
/// pembelian dicatat lewat transaksi beli).
@lazySingleton
class CreateMaterial {
  CreateMaterial(this._repository);

  final UsahaRepository _repository;

  Future<Result<void>> call(CreateMaterialParams params) async {
    if (params.name.trim().isEmpty) {
      return const Err(Failure(message: 'Nama bahan wajib diisi'));
    }
    if (params.unit.trim().isEmpty) {
      return const Err(Failure(message: 'Satuan wajib diisi'));
    }
    return _repository.createMaterial(
      name: params.name.trim(),
      unit: params.unit.trim(),
    );
  }
}

class RecordMaterialTxParams {
  const RecordMaterialTxParams({
    required this.materialId,
    required this.isPurchase,
    required this.quantity,
    required this.date,
    this.unitPrice,
    this.notes,
  });

  final String materialId;
  final bool isPurchase;
  final double quantity;
  final DateTime date;
  final double? unitPrice;
  final String? notes;
}

/// Catat pembelian/pemakaian bahan; stok disesuaikan server.
@lazySingleton
class RecordMaterialTransaction {
  RecordMaterialTransaction(this._repository);

  final UsahaRepository _repository;

  Future<Result<double>> call(RecordMaterialTxParams params) async {
    if (params.quantity <= 0) {
      return const Err(Failure(message: 'Jumlah harus lebih dari 0'));
    }
    if (params.isPurchase && params.unitPrice != null && params.unitPrice! < 0) {
      return const Err(Failure(message: 'Harga satuan tidak boleh negatif'));
    }
    if (params.date.isAfter(DateTime.now())) {
      return const Err(
          Failure(message: 'Tanggal transaksi tidak boleh di masa depan'));
    }
    return _repository.recordMaterialTransaction(
      materialId: params.materialId,
      type: params.isPurchase ? 'purchase' : 'usage',
      quantity: params.quantity,
      unitPrice: params.isPurchase ? params.unitPrice : null,
      date: params.date,
      notes: params.notes?.trim(),
    );
  }
}

@lazySingleton
class GetMaterialTransactions
    implements UseCase<List<MaterialTransaction>, NoParams> {
  GetMaterialTransactions(this._repository);

  final UsahaRepository _repository;

  @override
  Future<Result<List<MaterialTransaction>>> call(NoParams _) =>
      _repository.getMaterialTransactions();
}
