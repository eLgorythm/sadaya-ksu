import '../../../../core/utils/result.dart';
import '../entities/dana_entities.dart';

abstract interface class DanaRepository {
  Future<Result<List<FundTransaction>>> getFundTransactions();

  /// Saldo per akun dari buku besar (kas + bank + dana + Japinup) utk tahun.
  Future<Result<List<LedgerBalance>>> getLedgerBalances(int year);

  /// Catat kas masuk/keluar dana manual (posting jurnal via RPC).
  Future<Result<void>> createFundEntry({
    required String fundType,
    required bool isIncoming,
    required double amount,
    required String description,
    required DateTime date,
  });

  /// Total kumulatif transfer bank → kas.
  Future<Result<double>> getCairBankTotal();

  Future<Result<ShuCalculation>> calculateShu(int fiscalYear);

  Future<Result<List<ShuDistribution>>> getShuDistributions();

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
  });

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
  });

  Future<Result<void>> approveShu(String distributionId);

  Future<Result<void>> distributeShu(String distributionId);

  /// Membatalkan distribusi (kembali ke draft, alokasi dicabut).
  Future<Result<void>> cancelShuDistribution(String distributionId);

  /// Hanya untuk SHU yang belum terdistribusi.
  Future<Result<void>> deleteShu(String distributionId);
}
