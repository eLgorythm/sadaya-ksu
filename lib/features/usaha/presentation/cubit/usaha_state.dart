part of 'usaha_cubit.dart';

sealed class UsahaState extends Equatable {
  const UsahaState();

  @override
  List<Object?> get props => [];
}

class UsahaInitial extends UsahaState {
  const UsahaInitial();
}

class UsahaLoadInProgress extends UsahaState {
  const UsahaLoadInProgress();
}

class UsahaLoaded extends UsahaState {
  const UsahaLoaded({
    required this.materials,
    required this.materialTransactions,
    required this.productions,
    required this.sales,
  });

  final List<RawMaterial> materials;
  final List<MaterialTransaction> materialTransactions;
  final List<ProductionRecord> productions;
  final List<SaleRecord> sales;

  /// Omzet penjualan bulan berjalan.
  double get monthRevenue {
    final now = DateTime.now();
    return sales
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Total produksi bulan berjalan per satuan (kg & pack tidak
  /// boleh dijumlahkan).
  double get monthProductionKg {
    final now = DateTime.now();
    return productions
        .where(
          (p) =>
              p.date.year == now.year &&
              p.date.month == now.month &&
              p.unit == 'kg',
        )
        .fold(0, (sum, p) => sum + p.quantityProduced);
  }

  double get monthProductionGram {
    final now = DateTime.now();
    return productions
        .where(
          (p) =>
              p.date.year == now.year &&
              p.date.month == now.month &&
              p.unit == 'gram',
        )
        .fold(0, (sum, p) => sum + p.quantityProduced);
  }

  double get monthProductionPack {
    final now = DateTime.now();
    return productions
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .fold(0, (sum, p) => sum + (p.quantityPack ?? 0));
  }

  @override
  List<Object?> get props => [
    materials,
    materialTransactions,
    productions,
    sales,
  ];
}

class UsahaFailure extends UsahaState {
  const UsahaFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
