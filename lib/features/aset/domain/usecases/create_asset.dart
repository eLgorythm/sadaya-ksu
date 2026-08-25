import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/aset_repository.dart';

class CreateAssetParams extends Equatable {
  const CreateAssetParams({
    required this.name,
    required this.acquisitionDate,
    required this.cost,
    required this.salvageValue,
    required this.usefulLifeYears,
    this.description,
    this.id,
  });

  final String name;
  final String? description;
  final DateTime acquisitionDate;
  final double cost;
  final double salvageValue;
  final int usefulLifeYears;

  /// Terisi pada mode ubah aset.
  final String? id;

  bool get isEditing => id != null;

  CreateAssetParams copyWith({
    String? name,
    String? description,
    DateTime? acquisitionDate,
    double? cost,
    double? salvageValue,
    int? usefulLifeYears,
  }) {
    return CreateAssetParams(
      name: name ?? this.name,
      description: description ?? this.description,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      cost: cost ?? this.cost,
      salvageValue: salvageValue ?? this.salvageValue,
      usefulLifeYears: usefulLifeYears ?? this.usefulLifeYears,
      id: id,
    );
  }

  @override
  List<Object?> get props => [
        name,
        description,
        acquisitionDate,
        cost,
        salvageValue,
        usefulLifeYears,
        id,
      ];
}

/// Mendaftarkan aset tetap baru ke buku inventaris.
@injectable
class CreateAsset {
  CreateAsset(this._repository);

  final AsetRepository _repository;

  Future<Result<void>> call(CreateAssetParams params) async {
    if (params.name.trim().isEmpty) {
      return const Err(Failure(message: 'Nama aset wajib diisi'));
    }
    if (params.cost <= 0) {
      return const Err(Failure(message: 'Nilai perolehan harus lebih dari 0'));
    }
    if (params.salvageValue < 0) {
      return const Err(Failure(message: 'Nilai residu tidak boleh negatif'));
    }
    if (params.salvageValue >= params.cost) {
      return const Err(
          Failure(message: 'Nilai residu harus lebih kecil dari nilai perolehan'));
    }
    if (params.usefulLifeYears < 1 || params.usefulLifeYears > 50) {
      return const Err(Failure(message: 'Umur pakai harus 1-50 tahun'));
    }
    if (params.acquisitionDate.isAfter(DateTime.now())) {
      return const Err(
          Failure(message: 'Tanggal perolehan tidak boleh di masa depan'));
    }
    if (params.isEditing) {
      return _repository.updateAsset(
        id: params.id!,
        name: params.name.trim(),
        description: params.description?.trim(),
        acquisitionDate: params.acquisitionDate,
        cost: params.cost,
        salvageValue: params.salvageValue,
        usefulLifeYears: params.usefulLifeYears,
      );
    }
    return _repository.createAsset(
      name: params.name.trim(),
      description: params.description?.trim(),
      acquisitionDate: params.acquisitionDate,
      cost: params.cost,
      salvageValue: params.salvageValue,
      usefulLifeYears: params.usefulLifeYears,
    );
  }
}

/// Menghapus aset dari buku inventaris
/// (riwayat penyusutan ikut terhapus via FK cascade).
@injectable
class DeleteAsset {
  DeleteAsset(this._repository);

  final AsetRepository _repository;

  Future<Result<void>> call(String assetId) => _repository.deleteAsset(assetId);
}
