part of 'keuangan_cubit.dart';

sealed class KeuanganState extends Equatable {
  const KeuanganState();

  @override
  List<Object?> get props => [];
}

class KeuanganInitial extends KeuanganState {
  const KeuanganInitial();
}

class KeuanganLoadInProgress extends KeuanganState {
  const KeuanganLoadInProgress();
}

class KeuanganLoaded extends KeuanganState {
  const KeuanganLoaded({
    required this.cashEntries,
    required this.bankEntries,
    required this.categories,
    this.summary,
  });

  final List<CashBookEntry> cashEntries;
  final List<CashBookEntry> bankEntries;
  final List<CashCategoryOption> categories;

  /// Ringkasan saldo dari buku besar (kas + bank + dana + Japinup).
  final CashLedgerSummary? summary;

  double get cashBalance => _balanceOf(cashEntries);
  double get bankBalance => _balanceOf(bankEntries);

  static double _balanceOf(List<CashBookEntry> entries) {
    var total = 0.0;
    for (final e in entries) {
      total += e.isIncoming ? e.amount : -e.amount;
    }
    return total;
  }

  @override
  List<Object?> get props => [cashEntries, bankEntries, categories, summary];
}

class KeuanganFailure extends KeuanganState {
  const KeuanganFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
