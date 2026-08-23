import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/loan_entities.dart';
import '../repositories/loan_repository.dart';

@lazySingleton
class GetMemberLoans implements UseCase<List<LoanEntity>, String> {
  GetMemberLoans(this._repository);

  final LoanRepository _repository;

  @override
  Future<Result<List<LoanEntity>>> call(String memberId) =>
      _repository.getMemberLoans(memberId);
}

@lazySingleton
class GetLoanDetail implements UseCase<LoanDetail, String> {
  GetLoanDetail(this._repository);

  final LoanRepository _repository;

  @override
  Future<Result<LoanDetail>> call(String loanId) =>
      _repository.getLoanDetail(loanId);
}
