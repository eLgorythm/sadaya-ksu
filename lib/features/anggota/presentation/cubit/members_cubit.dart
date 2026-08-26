import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/usecases/set_member_status.dart';

part 'members_state.dart';

@lazySingleton
class MembersCubit extends Cubit<MembersState> {
  MembersCubit(this._repository, this._setStatus)
      : super(const MembersLoadSuccess([]));

  final MemberRepository _repository;
  final SetMemberStatus _setStatus;

  String _search = '';
  String? _statusFilter;

  Future<void> load({bool silent = false}) async {
    if (!silent || state is! MembersLoadSuccess) {
      emit(MembersLoadInProgress(
        search: _search,
        statusFilter: _statusFilter,
      ));
    }
    final result = await _repository.getMembers(
      MemberFilters(search: _search, status: _statusFilter),
    );
    switch (result) {
      case Ok(:final value):
        emit(MembersLoadSuccess(
          value,
          search: _search,
          statusFilter: _statusFilter,
        ));
      case Err(:final failure):
        emit(MembersFailure(
          message: failure.message,
          search: _search,
          statusFilter: _statusFilter,
        ));
    }
  }

  void searchChanged(String value) {
    _search = value;
    load();
  }

  void filterChanged(String? status) {
    _statusFilter = status;
    load();
  }

  Future<void> changeStatus({
    required String id,
    required String status,
  }) async {
    final result =
        await _setStatus(SetMemberStatusParams(id: id, status: status));
    switch (result) {
      case Ok():
        await load();
      case Err(:final failure):
        emit(MembersFailure(
          message: failure.message,
          search: _search,
          statusFilter: _statusFilter,
        ));
    }
  }
}
