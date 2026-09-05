import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/saving_entities.dart';
import '../repositories/savings_repository.dart';

class CreateSavingTransactionParams extends Equatable {
  const CreateSavingTransactionParams({
    required this.memberId,
    required this.type,
    required this.transactionType,
    required this.amount,
    this.description,
  });

  final String memberId;
  final SavingsTypeEntity type;
  final String transactionType;
  final double amount;
  final String? description;

  @override
  List<Object?> get props => [
    memberId,
    type,
    transactionType,
    amount,
    description,
  ];
}

@lazySingleton
class CreateSavingTransaction
    implements UseCase<SavingTransactionEntity, CreateSavingTransactionParams> {
  CreateSavingTransaction(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Result<SavingTransactionEntity>> call(
    CreateSavingTransactionParams params,
  ) async {
    if (params.transactionType != 'deposit' &&
        params.transactionType != 'withdrawal') {
      return const Err(Failure(message: 'Tipe transaksi tidak valid'));
    }
    if (params.amount <= 0) {
      return const Err(Failure(message: 'Nominal harus lebih dari 0'));
    }
    if (params.transactionType == 'withdrawal' && !params.type.isWithdrawable) {
      return Err(Failure(message: '${params.type.name} tidak dapat ditarik'));
    }
    if (params.type.isSystemManaged) {
      return const Err(
        Failure(
          message:
              'Simpanan Wajib Kredit dikelola otomatis dari cicilan pinjaman',
        ),
      );
    }
    return _repository.createTransaction(
      memberId: params.memberId,
      type: params.type,
      transactionType: params.transactionType,
      amount: params.amount,
      description: params.description?.trim(),
    );
  }
}
