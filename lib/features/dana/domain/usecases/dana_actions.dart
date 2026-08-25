import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../repositories/dana_repository.dart';

/// Menyetujui draft SHU (draft → approved).
@injectable
class ApproveShu {
  ApproveShu(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(String distributionId) =>
      _repository.approveShu(distributionId);
}

/// Mendistribusikan SHU (approved → distributed):
/// alokasi dana otomatis tercatat di buku dana via RPC.
@injectable
class DistributeShu {
  DistributeShu(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(String distributionId) =>
      _repository.distributeShu(distributionId);
}

/// Menghapus SHU yang belum terdistribusi.
@injectable
class DeleteShu {
  DeleteShu(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(String distributionId) =>
      _repository.deleteShu(distributionId);
}

/// Membatalkan distribusi SHU: alokasi buku dana dicabut,
/// status kembali ke draft agar bisa direvisi/didistribusikan ulang.
@injectable
class CancelShuDistribution {
  CancelShuDistribution(this._repository);

  final DanaRepository _repository;

  Future<Result<void>> call(String distributionId) =>
      _repository.cancelShuDistribution(distributionId);
}
