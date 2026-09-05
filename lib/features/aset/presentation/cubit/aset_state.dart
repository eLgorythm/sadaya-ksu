part of 'aset_cubit.dart';

sealed class AsetState extends Equatable {
  const AsetState();

  @override
  List<Object?> get props => [];
}

class AsetInitial extends AsetState {
  const AsetInitial();
}

class AsetLoadInProgress extends AsetState {
  const AsetLoadInProgress({required this.selectedYear});

  final int selectedYear;

  @override
  List<Object?> get props => [selectedYear];
}

class AsetLoaded extends AsetState {
  const AsetLoaded({
    required this.assets,
    required this.depreciationRows,
    required this.selectedYear,
  });

  final List<AssetItem> assets;
  final List<DepreciationRow> depreciationRows;
  final int selectedYear;

  double get totalCost =>
      assets.fold(0, (sum, a) => sum + (a.isActive ? a.cost : 0));

  double get totalAccumulated =>
      depreciationRows.fold(0, (sum, r) => sum + r.accumulated);

  double get totalBookValue =>
      depreciationRows.fold(0, (sum, r) => sum + r.bookValue);

  @override
  List<Object?> get props => [assets, depreciationRows, selectedYear];
}

class AsetFailure extends AsetState {
  const AsetFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
