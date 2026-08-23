import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/loan_entities.dart';
import '../repositories/loan_repository.dart';

@lazySingleton
class CreateLoan implements UseCase<LoanEntity, CreateLoanParams> {
  CreateLoan(this._repository);

  final LoanRepository _repository;

  @override
  Future<Result<LoanEntity>> call(CreateLoanParams params) async {
    if (params.principal <= 0) {
      return const Err(Failure(message: 'Jumlah pinjaman harus lebih dari 0'));
    }
    if (params.tenor < 1 || params.tenor > 50) {
      return const Err(Failure(message: 'Tenor harus antara 1 sampai 50 bulan'));
    }
    if (params.memberId.isEmpty) {
      return const Err(Failure(message: 'Anggota belum dipilih'));
    }
    return _repository.createLoan(
      memberId: params.memberId,
      principal: params.principal,
      tenor: params.tenor,
      disbursementDate: params.disbursementDate,
      notes: params.notes?.trim(),
    );
  }
}
