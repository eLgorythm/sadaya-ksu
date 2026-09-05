import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cash_repository.dart';

enum BankAction { danaMasuk, cairKas }

class BankActionParams extends Equatable {
  const BankActionParams({
    required this.action,
    required this.amount,
    required this.date,
    required this.description,
  });

  final BankAction action;
  final double amount;
  final DateTime date;
  final String description;

  @override
  List<Object?> get props => [action, amount, date, description];
}

@injectable
class BankActionEntry {
  BankActionEntry(this._repository);

  final CashRepository _repository;

  Future<Result<void>> call(BankActionParams params) async {
    if (params.amount <= 0) {
      return const Err(Failure(message: 'Nominal harus lebih dari 0'));
    }
    if (params.description.trim().isEmpty) {
      return const Err(Failure(message: 'Keterangan wajib diisi'));
    }
    switch (params.action) {
      case BankAction.danaMasuk:
        return _repository.bankDanaMasuk(
          amount: params.amount,
          date: params.date,
          description: params.description.trim(),
        );
      case BankAction.cairKas:
        return _repository.bankCairKas(
          amount: params.amount,
          date: params.date,
          description: params.description.trim(),
        );
    }
  }
}
