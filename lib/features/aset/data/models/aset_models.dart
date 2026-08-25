import '../../domain/entities/aset_entities.dart';

class AssetItemModel extends AssetItem {
  const AssetItemModel({
    required super.id,
    required super.name,
    required super.acquisitionDate,
    required super.cost,
    required super.salvageValue,
    required super.usefulLifeYears,
    required super.status,
    required super.description,
  });

  factory AssetItemModel.fromMap(Map<String, dynamic> map) {
    return AssetItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      acquisitionDate: DateTime.parse(map['acquisition_date'] as String),
      cost: (map['acquisition_cost'] as num).toDouble(),
      salvageValue: (map['salvage_value'] as num).toDouble(),
      usefulLifeYears: map['useful_life_years'] as int,
      status: map['status'] as String,
    );
  }
}

class DepreciationRowModel extends DepreciationRow {
  const DepreciationRowModel({
    required super.id,
    required super.assetId,
    required super.assetName,
    required super.fiscalYear,
    required super.amount,
    required super.accumulated,
    required super.bookValue,
  });

  factory DepreciationRowModel.fromMap(Map<String, dynamic> map) {
    return DepreciationRowModel(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      assetName: map['assets'] == null
          ? '(aset terhapus)'
          : (map['assets'] as Map)['name'] as String? ?? '',
      fiscalYear: map['fiscal_year'] as int,
      amount: (map['depreciation_amount'] as num).toDouble(),
      accumulated: (map['accumulated_depreciation'] as num).toDouble(),
      bookValue: (map['book_value'] as num).toDouble(),
    );
  }
}
