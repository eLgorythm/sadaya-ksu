import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/member_entity.dart';

class MemberFilters extends Equatable {
  const MemberFilters({this.search = '', this.status});

  final String search;
  final String? status;

  bool get isEmpty => search.isEmpty && status == null;

  @override
  List<Object?> get props => [search, status];
}

abstract interface class MemberRepository {
  Future<Result<List<MemberEntity>>> getMembers(MemberFilters filters);

  Future<Result<MemberEntity>> createMember({
    required String name,
    String? address,
    String? phone,
    required DateTime joinDate,
    String? notes,
  });

  Future<Result<MemberEntity>> updateMember({
    required String id,
    required int memberNumber,
    required String name,
    String? address,
    String? phone,
    required DateTime joinDate,
    String? notes,
  });

  Future<Result<void>> setStatus({required String id, required String status});
}
