import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cash_repository.dart';

class CreateCashEntryParams extends Equatable {
  const CreateCashEntryParams({
    required this.book,
    required this.direction,
    required this.counterAccount,
    required this.amount,
    required this.date,
    required this.description,
  });

  final String book;
  final String direction;
  final String counterAccount;
  final double amount;
  final DateTime date;
  final String description;

  CreateCashEntryParams copyWith({
    String? book,
    String? direction,
    String? counterAccount,
    double? amount,
    DateTime? date,
    String? description,
  }) {
    return CreateCashEntryParams(
      book: book ?? this.book,
      direction: direction ?? this.direction,
      counterAccount: counterAccount ?? this.counterAccount,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props =>
      [book, direction, counterAccount, amount, date, description];
}

@injectable
class CreateCashEntry {
  CreateCashEntry(this._repository);

  final CashRepository _repository;

  Future<Result<void>> call(CreateCashEntryParams params) async {
    if (params.amount <= 0) {
      return const Err(
          Failure(message: 'Nominal harus lebih dari 0'));
    }
    if (params.description.trim().isEmpty) {
      return const Err(Failure(message: 'Keterangan wajib diisi'));
    }
    if (params.counterAccount.isEmpty) {
      return const Err(Failure(message: 'Kategori wajib dipilih'));
    }
    return _repository.createEntry(
      book: params.book,
      direction: params.direction,
      counterAccount: params.counterAccount,
      amount: params.amount,
      date: params.date,
      description: params.description.trim(),
    );
  }
}
