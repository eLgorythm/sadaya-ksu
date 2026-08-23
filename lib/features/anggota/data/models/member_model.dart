import '../../domain/entities/member_entity.dart';

class MemberModel extends MemberEntity {
  const MemberModel({
    required super.id,
    required super.memberNumber,
    required super.name,
    required super.joinDate,
    super.address,
    super.phone,
    super.notes,
    super.status,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] as String,
      memberNumber: (map['member_number'] as num).toInt(),
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      joinDate: DateTime.parse(map['join_date'] as String),
      notes: map['notes'] as String?,
      status: (map['status'] as String?) ?? 'active',
    );
  }
}
