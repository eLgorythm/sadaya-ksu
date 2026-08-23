import '../../../../core/utils/result.dart';
import '../entities/saving_entities.dart';

abstract interface class SavingsRepository {
  Future<Result<List<SavingsTypeEntity>>> getSavingsTypes();

  Future<Result<MemberSavingsSummary>> getMemberSummary(String memberId);

  Future<Result<SavingTransactionEntity>> createTransaction({
    required String memberId,
    required SavingsTypeEntity type,
    required String transactionType,
    required double amount,
    String? description,
  });
}
