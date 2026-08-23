import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/saving_entities.dart';
import '../repositories/savings_repository.dart';

@lazySingleton
class GetSavingsTypes implements UseCase<List<SavingsTypeEntity>, NoParams> {
  GetSavingsTypes(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Result<List<SavingsTypeEntity>>> call(NoParams params) =>
      _repository.getSavingsTypes();
}

@lazySingleton
class GetMemberSavings implements UseCase<MemberSavingsSummary, String> {
  GetMemberSavings(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Result<MemberSavingsSummary>> call(String memberId) =>
      _repository.getMemberSummary(memberId);
}
