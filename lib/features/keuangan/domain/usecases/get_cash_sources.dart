import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/cash_entities.dart';
import '../repositories/cash_repository.dart';

/// Mengambil pemasukan Kas (akun 1111) per sumber untuk tahun tertentu.
@lazySingleton
class GetCashSources implements UseCase<CashSources, int> {
  GetCashSources(this._repository);

  final CashRepository _repository;

  @override
  Future<Result<CashSources>> call(int year) =>
      _repository.getCashSources(year);
}
