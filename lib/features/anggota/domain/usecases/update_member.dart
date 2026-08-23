import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/member_entity.dart';
import '../repositories/member_repository.dart';

class UpdateMemberParams extends Equatable {
  const UpdateMemberParams({
    required this.id,
    required this.memberNumber,
    required this.name,
    required this.joinDate,
    this.address,
    this.phone,
    this.notes,
  });

  final String id;
  final int memberNumber;
  final String name;
  final String? address;
  final String? phone;
  final DateTime joinDate;
  final String? notes;

  @override
  List<Object?> get props =>
      [id, memberNumber, name, address, phone, joinDate, notes];
}

@lazySingleton
class UpdateMember implements UseCase<MemberEntity, UpdateMemberParams> {
  UpdateMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<MemberEntity>> call(UpdateMemberParams params) async {
    if (params.id.isEmpty) {
      return const Err(Failure(message: 'ID anggota tidak valid'));
    }
    final name = params.name.trim();
    if (name.length < 3) {
      return const Err(Failure(message: 'Nama anggota minimal 3 karakter'));
    }
    return _repository.updateMember(
      id: params.id,
      memberNumber: params.memberNumber,
      name: name,
      address: params.address?.trim(),
      phone: params.phone?.trim(),
      joinDate: params.joinDate,
      notes: params.notes?.trim(),
    );
  }
}
