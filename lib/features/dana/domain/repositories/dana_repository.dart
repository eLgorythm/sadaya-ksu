import '../../../../core/utils/result.dart';
import '../entities/dana_entities.dart';

abstract interface class DanaRepository {
  Future<Result<List<FundTransaction>>> getFundTransactions();

  Future<Result<void>> createFundEntry({
    required String fundType,
    required bool isIncoming,
    required double amount,
    required String description,
    required DateTime date,
  });

  Future<Result<List<ShuDistribution>>> getShuDistributions();

  Future<Result<String>> createShuDistribution({
    required int fiscalYear,
    required double totalShu,
    required double taxAmount,
    required double netShu,
    double? reservePct,
    double? socialPct,
    double? educationPct,
    double? memberDividendPct,
    double? managementPct,
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
    double? memberDividendPct,
    double? managementPct,
    String? notes,
  });

  Future<Result<void>> approveShu(String distributionId);

  Future<Result<void>> distributeShu(String distributionId);

  /// Membatalkan distribusi (kembali ke draft, alokasi dicabut).
  Future<Result<void>> cancelShuDistribution(String distributionId);

  /// Hanya untuk SHU yang belum terdistribusi.
  Future<Result<void>> deleteShu(String distributionId);
}
