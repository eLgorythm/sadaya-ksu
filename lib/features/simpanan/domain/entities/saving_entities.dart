import 'package:equatable/equatable.dart';

class SavingsTypeEntity extends Equatable {
  const SavingsTypeEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.isWithdrawable,
    this.interestRate = 0,
  });

  final String id;
  final String code;
  final String name;
  final double interestRate;
  final bool isWithdrawable;

  bool get isSystemManaged => code == 'SWK';

  @override
  List<Object?> get props => [id, code, name, interestRate, isWithdrawable];
}

class SavingTransactionEntity extends Equatable {
  const SavingTransactionEntity({
    required this.id,
    required this.memberId,
    required this.typeCode,
    required this.typeName,
    required this.transactionType,
    required this.amount,
    required this.date,
    this.description,
    this.isVoid = false,
  });

  final String id;
  final String memberId;
  final String typeCode;
  final String typeName;
  final String transactionType;
  final double amount;
  final DateTime date;
  final String? description;
  final bool isVoid;

  bool get isDeposit => transactionType == 'deposit';

  /// Tanda bagi hasil SHU (jenis Dividen): "Dasim" atau "Dapin".
  /// Diturunkan dari keterangan transaksi DIV yang diisi otomatis saat
  /// distribusi SHU (Dasim = saldo SWB, Dapin = jasa pinjaman).
  String? get shuShareLabel {
    if (typeCode != 'DIV' || description == null) return null;
    final d = description!.toLowerCase();
    if (d.contains('dasim')) return 'Dasim';
    if (d.contains('dapin')) return 'Dapin';
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    memberId,
    typeCode,
    typeCode,
    amount,
    date,
    description,
    isVoid,
  ];
}

class MemberSavingsSummary extends Equatable {
  const MemberSavingsSummary({
    required this.balances,
    required this.transactions,
  });

  /// Saldo per kode jenis simpanan, mis. {'SP': 100000, 'SMS': 50000}
  final Map<String, double> balances;
  final List<SavingTransactionEntity> transactions;

  double balanceOf(String code) => balances[code] ?? 0;

  @override
  List<Object?> get props => [balances, transactions];
}
