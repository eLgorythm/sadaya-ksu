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

/// Satu akun dalam ringkasan buku kas (termasuk dana & Japinup).
///
/// [balance] adalah nilai utuh (|saldo natural|) — per model user:
/// kas = saldo koperasi; rincian dijumlahkan tanpa saling meniadakan.
class CashLedgerAccount extends Equatable {
  const CashLedgerAccount({
    required this.code,
    required this.name,
    required this.accountType,
    required this.balance,
  });

  final String code;
  final String name;
  final String accountType;
  final double balance;

  @override
  List<Object?> get props => [code, name, accountType, balance];
}

/// Ringkasan buku kas dari buku besar: total saldo berjalan + rincian per
/// akun (Kas, Bank, setiap dana, Japinup).
class CashLedgerSummary extends Equatable {
  const CashLedgerSummary({
    required this.accounts,
    required this.total,
  });

  final List<CashLedgerAccount> accounts;
  final double total;

  @override
  List<Object?> get props => [accounts, total];
}
