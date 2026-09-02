import '../../../../core/utils/result.dart';
import '../entities/cash_entities.dart';

abstract interface class CashRepository {
  Future<Result<List<CashBookEntry>>> getEntries(String book);

  Future<Result<CashLedgerSummary>> getLedgerSummary(int year);

  Future<Result<CashSources>> getCashSources(int year);

  Future<Result<List<CashCategoryOption>>> getCategories();

  Future<Result<String>> createCategory({
    required String name,
    required bool isIncome,
  });

  Future<Result<void>> bankDanaMasuk({
    required double amount,
    required DateTime date,
    required String description,
  });

  /// Tarik tunai dari rekening bank ke kas.
  Future<Result<void>> bankCairKas({
    required double amount,
    required DateTime date,
    required String description,
  });
}
