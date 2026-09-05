import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/member_repository.dart';

class SetMemberStatusParams extends Equatable {
  const SetMemberStatusParams({required this.id, required this.status});

  final String id;
  final String status;

  @override
  List<Object?> get props => [id, status];
}

@lazySingleton
class SetMemberStatus implements UseCase<void, SetMemberStatusParams> {
  SetMemberStatus(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<void>> call(SetMemberStatusParams params) {
    if (params.status != 'active' && params.status != 'inactive') {
      return Future.value(const Err(Failure(message: 'Status tidak valid')));
    }
    return _repository.setStatus(id: params.id, status: params.status);
  }
}
