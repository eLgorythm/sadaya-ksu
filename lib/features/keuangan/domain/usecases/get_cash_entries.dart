import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/cash_entities.dart';
import '../repositories/cash_repository.dart';

/// [book] = 'cash' atau 'bank'.
@lazySingleton
class GetCashEntries implements UseCase<List<CashBookEntry>, String> {
  GetCashEntries(this._repository);

  final CashRepository _repository;

  @override
  Future<Result<List<CashBookEntry>>> call(String book) =>
      _repository.getEntries(book);
}

@lazySingleton
class GetCashCategories implements UseCase<List<CashCategoryOption>, NoParams> {
  GetCashCategories(this._repository);

  final CashRepository _repository;

  @override
  Future<Result<List<CashCategoryOption>>> call(NoParams _) =>
      _repository.getCategories();
}
