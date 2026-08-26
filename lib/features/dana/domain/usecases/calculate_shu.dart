import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../entities/dana_entities.dart';
import '../repositories/dana_repository.dart';

/// Menghitung SHU dari buku besar (ledger) untuk tahun fiskal tertentu.
/// Mengembalikan total pendapatan, pengeluaran, dan laba bersih.
@injectable
class CalculateShu {
  CalculateShu(this._repository);

  final DanaRepository _repository;

  Future<Result<ShuCalculation>> call(int fiscalYear) =>
      _repository.calculateShu(fiscalYear);
}
