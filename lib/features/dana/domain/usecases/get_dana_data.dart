import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/dana_entities.dart';
import '../repositories/dana_repository.dart';

@lazySingleton
class GetFundTransactions
    implements UseCase<List<FundTransaction>, NoParams> {
  GetFundTransactions(this._repository);

  final DanaRepository _repository;

  @override
  Future<Result<List<FundTransaction>>> call(NoParams _) =>
      _repository.getFundTransactions();
}

@lazySingleton
class GetLedgerBalances implements UseCase<List<LedgerBalance>, int> {
  GetLedgerBalances(this._repository);

  final DanaRepository _repository;

  @override
  Future<Result<List<LedgerBalance>>> call(int year) =>
      _repository.getLedgerBalances(year);
}

@lazySingleton
class GetShuDistributions
    implements UseCase<List<ShuDistribution>, NoParams> {
  GetShuDistributions(this._repository);

  final DanaRepository _repository;

  @override
  Future<Result<List<ShuDistribution>>> call(NoParams _) =>
      _repository.getShuDistributions();
}
