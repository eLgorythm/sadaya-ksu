import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/usaha_entities.dart';
import '../../domain/repositories/usaha_repository.dart';
import '../datasources/usaha_remote_data_source.dart';
import '../models/usaha_models.dart';

@LazySingleton(as: UsahaRepository)
class UsahaRepositoryImpl implements UsahaRepository {
  UsahaRepositoryImpl(this._dataSource);

  final UsahaRemoteDataSource _dataSource;

  @override
  Future<Result<List<RawMaterial>>> getMaterials() async {
    try {
      final rows = await _dataSource.fetchMaterials();
      return Ok(rows.map(RawMaterialModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat bahan baku'));
    }
  }

  @override
  Future<Result<void>> createMaterial({
    required String name,
    required String unit,
  }) async {
    try {
      await _dataSource.insertMaterial(name: name, unit: unit);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan bahan baku'));
    }
  }

  @override
  Future<Result<double>> recordMaterialTransaction({
    required String materialId,
    required String type,
    required double quantity,
    double? unitPrice,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final stock = await _dataSource.rpcRecordMaterialTransaction(
        materialId: materialId,
        type: type,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        notes: notes,
      );
      return Ok(stock);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal mencatat transaksi bahan'));
    }
  }

  @override
  Future<Result<List<MaterialTransaction>>> getMaterialTransactions() async {
    try {
      final rows = await _dataSource.fetchMaterialTransactions();
      return Ok(rows.map(MaterialTransactionModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat transaksi bahan'));
    }
  }

  @override
  Future<Result<List<ProductionRecord>>> getProductions() async {
    try {
      final rows = await _dataSource.fetchProductions();
      return Ok(rows.map(ProductionRecordModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat data produksi'));
    }
  }

  @override
  Future<Result<void>> createProduction({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    double? quantityPack,
    double? cost,
    String? notes,
  }) async {
    try {
      await _dataSource.insertProduction(
        productType: productType,
        date: date,
        quantity: quantity,
        unit: unit,
        quantityPack: quantityPack,
        cost: cost,
        notes: notes,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan produksi'));
    }
  }

  @override
  Future<Result<List<SaleRecord>>> getSales() async {
    try {
      final rows = await _dataSource.fetchSales();
      return Ok(rows.map(SaleRecordModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat data penjualan'));
    }
  }

  @override
  Future<Result<void>> createSale({
    required String productType,
    required DateTime date,
    required double quantity,
    required String unit,
    required double unitPrice,
    String? buyer,
    String? notes,
  }) async {
    try {
      await _dataSource.insertSale(
        productType: productType,
        date: date,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        buyer: buyer,
        notes: notes,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan penjualan'));
    }
  }

  @override
  Future<Result<void>> deleteSale(String id) async {
    try {
      await _dataSource.deleteSale(id);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menghapus penjualan'));
    }
  }
}
