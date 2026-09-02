part of 'dana_cubit.dart';

sealed class DanaState extends Equatable {
  const DanaState();

  @override
  List<Object?> get props => [];
}

class DanaInitial extends DanaState {
  const DanaInitial();
}

class DanaLoadInProgress extends DanaState {
  const DanaLoadInProgress();
}

class DanaLoaded extends DanaState {
  const DanaLoaded({
    required this.fundEntries,
    required this.shuList,
    this.ledgerBalances = const [],
  });

  final List<FundTransaction> fundEntries;
  final List<ShuDistribution> shuList;
  final List<LedgerBalance> ledgerBalances;

  /// Saldo tiap jenis dana (pemasukan - pengeluaran).
  Map<String, double> get balances {
    final result = <String, double>{};
    for (final e in fundEntries) {
      final delta = e.isIncoming ? e.amount : -e.amount;
      result[e.fundType] = (result[e.fundType] ?? 0) + delta;
    }
    return result;
  }

  double balanceOf(String fundType) => balances[fundType] ?? 0;

  /// Saldo buku besar per kode akun (nilai utuh).
  double ledgerBalanceOf(String code) {
    for (final b in ledgerBalances) {
      if (b.code == code) return b.balance;
    }
    return 0;
  }

  /// Saldo Japinup (jasa pinjaman) dari buku besar.
  double get japinupBalance => ledgerBalanceOf('4111');

  @override
  List<Object?> get props => [fundEntries, shuList, ledgerBalances];
}

class DanaFailure extends DanaState {
  const DanaFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
