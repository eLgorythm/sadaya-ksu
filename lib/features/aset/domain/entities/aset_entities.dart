import 'package:equatable/equatable.dart';

class AssetItem extends Equatable {
  const AssetItem({
    required this.id,
    required this.name,
    required this.acquisitionDate,
    required this.cost,
    required this.salvageValue,
    required this.usefulLifeYears,
    required this.status,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime acquisitionDate;
  final double cost;
  final double salvageValue;
  final int usefulLifeYears;
  final String status;

  bool get isActive => status == 'active';

  /// Dasar yang disusutkan = nilai perolehan − nilai residu.
  double get depreciableBase => (cost - salvageValue).clamp(0, double.infinity);

  /// Penyusutan garis lurus per tahun.
  double get annualDepreciation =>
      usefulLifeYears > 0 ? depreciableBase / usefulLifeYears : 0;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        acquisitionDate,
        cost,
        salvageValue,
        usefulLifeYears,
        status,
      ];
}

/// Satu baris buku penyusutan untuk tahun fiskal tertentu.
class DepreciationRow extends Equatable {
  const DepreciationRow({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.fiscalYear,
    required this.amount,
    required this.accumulated,
    required this.bookValue,
  });

  final String id;
  final String assetId;
  final String assetName;
  final int fiscalYear;
  final double amount;
  final double accumulated;
  final double bookValue;

  @override
  List<Object?> get props => [
        id,
        assetId,
        assetName,
        fiscalYear,
        amount,
        accumulated,
        bookValue,
      ];
}
