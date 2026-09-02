import '../../../../core/utils/result.dart';
import '../entities/cash_entities.dart';

abstract interface class CashRepository {
  Future<Result<List<CashBookEntry>>> getEntries(String book);

  Future<Result<CashLedgerSummary>> getLedgerSummary(int year);

  Future<Result<List<CashCategoryOption>>> getCategories();

  Future<Result<String>> createCategory({
    required String name,
    required bool isIncome,
  });

  Future<Result<void>> createEntry({
    required String book,
    required String direction,
    required String counterAccount,
    required double amount,
    required DateTime date,
    required String description,
  });
}
