import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cash_repository.dart';

class CreateCashCategoryParams extends Equatable {
  const CreateCashCategoryParams({required this.name, required this.isIncome});

  final String name;
  final bool isIncome;

  @override
  List<Object?> get props => [name, isIncome];
}

/// Membuat kategori transaksi baru + kode COA otomatis di server.
/// Mengembalikan kode COA yang dibuat.
@injectable
class CreateCashCategory {
  CreateCashCategory(this._repository);

  final CashRepository _repository;

  Future<Result<String>> call(CreateCashCategoryParams params) async {
    if (params.name.trim().isEmpty) {
      return const Err(Failure(message: 'Nama kategori wajib diisi'));
    }
    return _repository.createCategory(
      name: params.name.trim(),
      isIncome: params.isIncome,
    );
  }
}
