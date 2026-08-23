import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/member_entity.dart';
import '../repositories/member_repository.dart';

@lazySingleton
class GetMembers implements UseCase<List<MemberEntity>, MemberFilters> {
  GetMembers(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<List<MemberEntity>>> call(MemberFilters params) =>
      _repository.getMembers(params);
}
