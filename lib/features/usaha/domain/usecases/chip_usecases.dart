import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/usaha_repository.dart';

/// Ambil saldo kas Unit Krisado (akun mandiri 1114).
@lazySingleton
class GetChipBalance implements UseCase<double, NoParams> {
  GetChipBalance(this._repository);

  final UsahaRepository _repository;

  @override
  Future<Result<double>> call(NoParams _) => _repository.getChipBalance();
}

class ChipAmbilDariBankParams extends Equatable {
  const ChipAmbilDariBankParams({
    required this.amount,
    required this.date,
    required this.description,
  });

  final double amount;
  final DateTime date;
  final String description;

  @override
  List<Object?> get props => [amount, date, description];
}

/// Tarik uang dari rekening bank (Buku Bank) ke kas Unit Krisado.
@lazySingleton
class ChipAmbilDariBank {
  ChipAmbilDariBank(this._repository);

  final UsahaRepository _repository;

  Future<Result<void>> call(ChipAmbilDariBankParams params) async {
    if (params.amount <= 0) {
      return const Err(Failure(message: 'Nominal harus lebih dari 0'));
    }
    if (params.description.trim().isEmpty) {
      return const Err(Failure(message: 'Keterangan wajib diisi'));
    }
    if (params.date.isAfter(DateTime.now())) {
      return const Err(Failure(message: 'Tanggal tidak boleh di masa depan'));
    }
    return _repository.chipAmbilDariBank(
      amount: params.amount,
      date: params.date,
      description: params.description.trim(),
    );
  }
}
