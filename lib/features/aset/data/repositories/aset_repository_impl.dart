import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/aset_entities.dart';
import '../../domain/repositories/aset_repository.dart';
import '../datasources/aset_remote_data_source.dart';
import '../models/aset_models.dart';

@LazySingleton(as: AsetRepository)
class AsetRepositoryImpl implements AsetRepository {
  AsetRepositoryImpl(this._dataSource);

  final AsetRemoteDataSource _dataSource;

  @override
  Future<Result<List<AssetItem>>> getAssets() async {
    try {
      final rows = await _dataSource.fetchAssets();
      return Ok(rows.map(AssetItemModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat daftar aset'));
    }
  }

  @override
  Future<Result<List<DepreciationRow>>> getDepreciations(int fiscalYear) async {
    try {
      final rows = await _dataSource.fetchDepreciations(fiscalYear);
      return Ok(rows.map(DepreciationRowModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat buku penyusutan'));
    }
  }

  @override
  Future<Result<void>> createAsset({
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  }) async {
    try {
      await _dataSource.insertAsset(
        name: name,
        description: description,
        acquisitionDate: acquisitionDate,
        cost: cost,
        salvageValue: salvageValue,
        usefulLifeYears: usefulLifeYears,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan aset'));
    }
  }

  @override
  Future<Result<void>> updateAsset({
    required String id,
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  }) async {
    try {
      await _dataSource.updateAsset(
        id: id,
        name: name,
        description: description,
        acquisitionDate: acquisitionDate,
        cost: cost,
        salvageValue: salvageValue,
        usefulLifeYears: usefulLifeYears,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memperbarui aset'));
    }
  }

  @override
  Future<Result<void>> deleteAsset(String id) async {
    try {
      await _dataSource.deleteAsset(id);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menghapus aset'));
    }
  }

  @override
  Future<Result<int>> recalculateDepreciations(int fiscalYear) async {
    try {
      final count = await _dataSource.rpcRecalculateDepreciations(fiscalYear);
      return Ok(count);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menghitung penyusutan'));
    }
  }
}
