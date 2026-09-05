import 'package:equatable/equatable.dart';

class MemberEntity extends Equatable {
  const MemberEntity({
    required this.id,
    required this.memberNumber,
    required this.name,
    required this.joinDate,
    this.address,
    this.phone,
    this.notes,
    this.status = 'active',
  });

  final String id;
  final int memberNumber;
  final String name;
  final String? address;
  final String? phone;
  final DateTime joinDate;
  final String? notes;
  final String status;

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
    id,
    memberNumber,
    name,
    address,
    phone,
    joinDate,
    notes,
    status,
  ];
}
