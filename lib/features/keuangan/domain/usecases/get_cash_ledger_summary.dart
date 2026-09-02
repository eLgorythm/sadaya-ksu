import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/cash_entities.dart';
import '../repositories/cash_repository.dart';

/// Mengambil ringkasan buku kas dari buku besar untuk tahun tertentu.
@lazySingleton
class GetCashLedgerSummary implements UseCase<CashLedgerSummary, int> {
  GetCashLedgerSummary(this._repository);

  final CashRepository _repository;

  @override
  Future<Result<CashLedgerSummary>> call(int year) =>
      _repository.getLedgerSummary(year);
}