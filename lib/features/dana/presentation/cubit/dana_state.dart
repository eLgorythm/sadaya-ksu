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
    this.cairBankTotal = 0,
  });

  final List<FundTransaction> fundEntries;
  final List<ShuDistribution> shuList;
  final List<LedgerBalance> ledgerBalances;

  /// Total kumulatif transfer bank → kas.
  final double cairBankTotal;

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

  /// Total Kas = jumlah saldo 7 pos dana dari buku besar.
  double get totalKas {
    var total = 0.0;
    for (final pos in kFundPosOrder) {
      total += ledgerBalanceOf(kFundPosAccounts[pos]!);
    }
    return total;
  }

  @override
  List<Object?> get props => [
    fundEntries,
    shuList,
    ledgerBalances,
    cairBankTotal,
  ];
}

class DanaFailure extends DanaState {
  const DanaFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
