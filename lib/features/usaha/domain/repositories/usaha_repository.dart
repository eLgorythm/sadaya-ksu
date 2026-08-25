import '../../../../core/utils/result.dart';
import '../entities/usaha_entities.dart';

abstract interface class UsahaRepository {
  Future<Result<List<RawMaterial>>> getMaterials();

  /// Daftarkan jenis bahan baru (master data, stok mulai 0).
  /// Pembelian dicatat terpisah lewat transaksi beli.
  Future<Result<void>> createMaterial({
    required String name,
    required String unit,
  });

  /// Catat beli/pakai; mengembalikan stok terbaru.
  Future<Result<double>> recordMaterialTransaction({
    required String materialId,
    required String type,
    required double quantity,
    double? unitPrice,
    required DateTime date,
    String? notes,
  });

  Future<Result<List<MaterialTransaction>>> getMaterialTransactions();

  Future<Result<List<ProductionRecord>>> getProductions();

  Future<Result<void>> createProduction({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    double? quantityPack,
    double? cost,
    String? notes,
  });

  Future<Result<List<SaleRecord>>> getSales();

  Future<Result<void>> createSale({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    required double unitPrice,
    String? buyer,
    String? notes,
  });

  Future<Result<void>> deleteSale(String id);
}
