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
  });

  final List<FundTransaction> fundEntries;
  final List<ShuDistribution> shuList;

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

  @override
  List<Object?> get props => [fundEntries, shuList];
}

class DanaFailure extends DanaState {
  const DanaFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
