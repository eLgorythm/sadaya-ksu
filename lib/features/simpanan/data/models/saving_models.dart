import '../../domain/entities/saving_entities.dart';

class SavingsTypeModel extends SavingsTypeEntity {
  const SavingsTypeModel({
    required super.id,
    required super.code,
    required super.name,
    required super.isWithdrawable,
    super.interestRate,
  });

  factory SavingsTypeModel.fromMap(Map<String, dynamic> map) {
    return SavingsTypeModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      interestRate: double.tryParse('${map['interest_rate']}') ?? 0,
      isWithdrawable: (map['is_withdrawable'] as bool?) ?? false,
    );
  }
}

class SavingTransactionModel extends SavingTransactionEntity {
  const SavingTransactionModel({
    required super.id,
    required super.memberId,
    required super.typeCode,
    required super.typeName,
    required super.transactionType,
    required super.amount,
    required super.date,
    super.description,
    super.isVoid,
  });

  factory SavingTransactionModel.fromMap(Map<String, dynamic> map) {
    final type = map['savings_types'] as Map<String, dynamic>?;
    return SavingTransactionModel(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      typeCode: (type?['code'] as String?) ?? '-',
      typeName: (type?['name'] as String?) ?? '-',
      transactionType: map['transaction_type'] as String,
      amount: double.tryParse('${map['amount']}') ?? 0,
      date: DateTime.parse(map['transaction_date'] as String),
      description: map['description'] as String?,
      isVoid: (map['is_void'] as bool?) ?? false,
    );
  }

  factory SavingTransactionModel.fromRpcRow(
    Map<String, dynamic> map, {
    required String typeCode,
    required String typeName,
  }) {
    return SavingTransactionModel(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      typeCode: typeCode,
      typeName: typeName,
      transactionType: map['transaction_type'] as String,
      amount: double.tryParse('${map['amount']}') ?? 0,
      date: DateTime.parse(map['transaction_date'] as String),
      description: map['description'] as String?,
      isVoid: (map['is_void'] as bool?) ?? false,
    );
  }
}
