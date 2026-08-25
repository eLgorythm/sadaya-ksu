import 'package:equatable/equatable.dart';

/// Satu baris transaksi pada Buku Kas Harian atau Buku Bank.
class CashBookEntry extends Equatable {
  const CashBookEntry({
    required this.id,
    required this.date,
    required this.direction,
    required this.amount,
    required this.description,
    this.categoryName,
  });

  final String id;
  final DateTime date;

  /// 'in' = uang masuk, 'out' = uang keluar.
  final String direction;
  final double amount;
  final String description;
  final String? categoryName;

  bool get isIncoming => direction == 'in';

  @override
  List<Object?> get props =>
      [id, date, direction, amount, description, categoryName];
}

/// Opsi kategori/akun lawan untuk form input.
class CashCategoryOption extends Equatable {
  const CashCategoryOption({
    required this.code,
    required this.name,
    required this.isIncome,
  });

  /// Kode COA yang dipakai sebagai akun lawan jurnal.
  final String code;
  final String name;
  final bool isIncome;

  @override
  List<Object?> get props => [code, name, isIncome];
}
