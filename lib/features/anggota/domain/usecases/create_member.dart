import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/member_entity.dart';
import '../repositories/member_repository.dart';

class CreateMemberParams extends Equatable {
  const CreateMemberParams({
    required this.name,
    required this.joinDate,
    this.address,
    this.phone,
    this.notes,
  });

  final String name;
  final String? address;
  final String? phone;
  final DateTime joinDate;
  final String? notes;

  @override
  List<Object?> get props => [name, address, phone, joinDate, notes];
}

@lazySingleton
class CreateMember implements UseCase<MemberEntity, CreateMemberParams> {
  CreateMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<Result<MemberEntity>> call(CreateMemberParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) {
      return const Err(Failure(message: 'Nama anggota wajib diisi'));
    }
    if (name.length < 3) {
      return const Err(Failure(message: 'Nama anggota minimal 3 karakter'));
    }
    return _repository.createMember(
      name: name,
      address: params.address?.trim(),
      phone: params.phone?.trim(),
      joinDate: params.joinDate,
      notes: params.notes?.trim(),
    );
  }
}
