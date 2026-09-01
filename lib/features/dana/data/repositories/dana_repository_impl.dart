import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/dana_entities.dart';
import '../../domain/repositories/dana_repository.dart';
import '../datasources/dana_remote_data_source.dart';
import '../models/dana_models.dart';

@LazySingleton(as: DanaRepository)
class DanaRepositoryImpl implements DanaRepository {
  DanaRepositoryImpl(this._dataSource);

  final DanaRemoteDataSource _dataSource;

  @override
  Future<Result<List<FundTransaction>>> getFundTransactions() async {
    try {
      final rows = await _dataSource.fetchFundTransactions();
      return Ok(rows.map(FundTransactionModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat buku dana'));
    }
  }

  @override
  Future<Result<void>> createFundEntry({
    required String fundType,
    required bool isIncoming,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _dataSource.insertFundTransaction(
        fundType: fundType,
        isIncoming: isIncoming,
        amount: amount,
        description: description,
        date: date,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan transaksi dana'));
    }
  }

  @override
  Future<Result<ShuCalculation>> calculateShu(int fiscalYear) async {
    try {
      final row = await _dataSource.fetchShuCalculation(fiscalYear);
      return Ok(ShuCalculation(
        totalRevenue: (row['total_revenue'] as num).toDouble(),
        totalExpense: (row['total_expense'] as num).toDouble(),
        netShu: (row['net_shu'] as num).toDouble(),
      ));
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menghitung SHU dari buku besar'));
    }
  }

  @override
  Future<Result<List<ShuDistribution>>> getShuDistributions() async {
    try {
      final rows = await _dataSource.fetchShuDistributions();
      return Ok(rows.map(ShuDistributionModel.fromMap).toList());
    } catch (_) {
      return const Err(Failure(message: 'Gagal memuat daftar SHU'));
    }
  }

  @override
  Future<Result<String>> createShuDistribution({
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    required double netShu,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberSavingsPct,
    double? memberServicePct,
    double? managementPct,
    double? staffPct,
    double? developmentPct,
    String? notes,
  }) async {
    try {
      final id = await _dataSource.insertShuDistribution(
        fiscalYear: fiscalYear,
        totalShu: totalShu,
        taxAmount: taxAmount,
        netShu: netShu,
        reservePct: reservePct,
        socialPct: socialPct,
        educationPct: educationPct,
        memberSavingsPct: memberSavingsPct,
        memberServicePct: memberServicePct,
        managementPct: managementPct,
        staffPct: staffPct,
        developmentPct: developmentPct,
        notes: notes,
      );
      return Ok(id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Err(
            Failure(message: 'SHU untuk tahun fiskal itu sudah ada'));
      }
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyimpan perhitungan SHU'));
    }
  }

  @override
  Future<Result<void>> updateShuDistribution({
    required String id,
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    required double netShu,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberSavingsPct,
    double? memberServicePct,
    double? managementPct,
    double? staffPct,
    double? developmentPct,
    String? notes,
  }) async {
    try {
      await _dataSource.updateShuDistribution(
        id: id,
        fiscalYear: fiscalYear,
        totalShu: totalShu,
        taxAmount: taxAmount,
        netShu: netShu,
        reservePct: reservePct,
        socialPct: socialPct,
        educationPct: educationPct,
        memberSavingsPct: memberSavingsPct,
        memberServicePct: memberServicePct,
        managementPct: managementPct,
        staffPct: staffPct,
        developmentPct: developmentPct,
        notes: notes,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Err(
            Failure(message: 'SHU untuk tahun fiskal itu sudah ada'));
      }
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal memperbarui perhitungan SHU'));
    }
  }

  @override
  Future<Result<void>> cancelShuDistribution(String distributionId) async {
    try {
      await _dataSource.rpcCancelShuDistribution(distributionId);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal membatalkan distribusi SHU'));
    }
  }

  @override
  Future<Result<void>> approveShu(String distributionId) async {
    try {
      await _dataSource.updateShuStatus(
        distributionId: distributionId,
        status: 'approved',
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menyetujui SHU'));
    }
  }

  @override
  Future<Result<void>> deleteShu(String distributionId) async {
    try {
      await _dataSource.deleteShu(distributionId);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal menghapus data SHU'));
    }
  }

  @override
  Future<Result<void>> distributeShu(String distributionId) async {
    try {
      await _dataSource.rpcDistributeShu(distributionId);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: e.message));
    } catch (_) {
      return const Err(Failure(message: 'Gagal mendistribusikan SHU'));
    }
  }
}
