import '../../../../core/utils/result.dart';
import '../entities/aset_entities.dart';

abstract interface class AsetRepository {
  Future<Result<List<AssetItem>>> getAssets();

  Future<Result<List<DepreciationRow>>> getDepreciations(int fiscalYear);

  Future<Result<void>> createAsset({
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  });

  Future<Result<void>> updateAsset({
    required String id,
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  });

  Future<Result<void>> deleteAsset(String id);

  /// Mengembalikan jumlah baris penyusutan yang dibuat.
  Future<Result<int>> recalculateDepreciations(int fiscalYear);
}
