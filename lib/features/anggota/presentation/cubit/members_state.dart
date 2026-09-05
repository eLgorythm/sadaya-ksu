part of 'members_cubit.dart';

sealed class MembersState extends Equatable {
  const MembersState({this.search = '', this.statusFilter});

  final String search;
  final String? statusFilter;

  @override
  List<Object?> get props => [search, statusFilter];
}

class MembersLoadInProgress extends MembersState {
  const MembersLoadInProgress({super.search, super.statusFilter});
}

class MembersLoadSuccess extends MembersState {
  const MembersLoadSuccess(this.members, {super.search, super.statusFilter});

  final List<MemberEntity> members;

  @override
  List<Object?> get props => [...super.props, members];
}

class MembersFailure extends MembersState {
  const MembersFailure({
    required this.message,
    super.search,
    super.statusFilter,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
