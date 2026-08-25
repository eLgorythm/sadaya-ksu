import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/dana_repository.dart';

class CreateFundEntryParams extends Equatable {
  const CreateFundEntryParams({
    required this.fundType,
    required this.isIncoming,
    required this.amount,
    required this.description,
    required this.date,
  });

  final String fundType;
  final bool isIncoming;
  final double amount;
  final String description;
  final DateTime date;

  @override
  List<Object?> get props => [fundType, isIncoming, amount, description, date];
}

/// Mencatat penerimaan/penggunaan dana manual di buku dana.
@injectable
class CreateFundEntry {
  CreateFundEntry(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(CreateFundEntryParams params) async {
    if (params.fundType.isEmpty) {
      return const Err(Failure(message: 'Jenis dana wajib dipilih'));
    }
    if (params.amount <= 0) {
      return const Err(Failure(message: 'Nominal harus lebih dari 0'));
    }
    if (params.description.trim().isEmpty) {
      return const Err(Failure(message: 'Keterangan wajib diisi'));
    }
    return _repository.createFundEntry(
      fundType: params.fundType,
      isIncoming: params.isIncoming,
      amount: params.amount,
      description: params.description.trim(),
      date: params.date,
    );
  }
}
