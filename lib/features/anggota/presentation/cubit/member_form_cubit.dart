import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/usecases/create_member.dart';
import '../../domain/usecases/update_member.dart';

part 'member_form_state.dart';

@injectable
class MemberFormCubit extends Cubit<MemberFormState> {
  MemberFormCubit(this._createMember, this._updateMember)
      : super(const MemberFormInitial());

  final CreateMember _createMember;
  final UpdateMember _updateMember;

  Future<void> save({
    String? id,
    required int memberNumber,
    required String name,
    String? address,
    String? phone,
    required DateTime joinDate,
    String? notes,
  }) async {
    emit(const MemberFormSaving());
    final Result<MemberEntity> result;
    if (id == null) {
      result = await _createMember(CreateMemberParams(
        name: name,
        address: address,
        phone: phone,
        joinDate: joinDate,
        notes: notes,
      ));
    } else {
      result = await _updateMember(UpdateMemberParams(
        id: id,
        memberNumber: memberNumber,
        name: name,
        address: address,
        phone: phone,
        joinDate: joinDate,
        notes: notes,
      ));
    }
    switch (result) {
      case Ok(:final value):
        emit(MemberFormSuccess(member: value, isEdit: id != null));
      case Err(:final failure):
        emit(MemberFormFailure(failure.message));
    }
  }

  void reset() => emit(const MemberFormInitial());
}
