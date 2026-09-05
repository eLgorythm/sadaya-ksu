import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/aset_entities.dart';
import '../repositories/aset_repository.dart';

@lazySingleton
class GetAssets implements UseCase<List<AssetItem>, NoParams> {
  GetAssets(this._repository);

  final AsetRepository _repository;

  @override
  Future<Result<List<AssetItem>>> call(NoParams _) => _repository.getAssets();
}

@lazySingleton
class GetDepreciations implements UseCase<List<DepreciationRow>, int> {
  GetDepreciations(this._repository);

  final AsetRepository _repository;

  @override
  Future<Result<List<DepreciationRow>>> call(int fiscalYear) =>
      _repository.getDepreciations(fiscalYear);
}

@lazySingleton
class RecalculateDepreciations implements UseCase<int, int> {
  RecalculateDepreciations(this._repository);

  final AsetRepository _repository;

  @override
  Future<Result<int>> call(int fiscalYear) =>
      _repository.recalculateDepreciations(fiscalYear);
}
